global EditCommands
global UtilityHandlers
global LogFileParser
global MessageUtility
global PDFController
global DVIController
global TeXDocController
global appController
global RefPanelController
global ToolPaletteController
global EditorClient

--general libs
global PathAnalyzer
global ShellUtils
global TerminalCommander
global PathConverter
global StringEngine
global FrontDocument
global XFile

--special values
global comDelim
global _backslash
global sQ -- start of quotation character
global eQ -- end of quotation character

property ignoringErrorList : {1200, 1205, 1210, 1220, 1230, 1240}
property supportedMode : {"TEX", "LaTeX"}

on texdoc_for_firstdoc given showing_message:message_flag, need_file:need_file_flag
	if EditorClient's exists_document() then
		set a_tex_file to EditorClient's document_file_as_alias()
		if (a_tex_file is missing value) then
			if (need_file_flag) then
				if message_flag then
					set docname to EditorClient's document_name()
					set a_message to UtilityHandlers's localized_string("DocumentIsNotSaved", {docname})
					EditorClient's show_message(a_message)
					error "The document is not saved." number 1200
				end if
				return missing value
			end if
		end if
		
		if (EditorClient's document_mode() is not in supportedMode) then
			if message_flag then
				set docname to EditorClient's document_name()
				set theMessage to UtilityHandlers's localized_string("invalidMode", {docname})
				showMessage(theMessage) of MessageUtility
				error "The mode of the document is not supported." number 1205
			end if
			return missing value
		end if
	else
		if message_flag then
			set theMessage to localized string "noDocument"
			showMessage(theMessage) of MessageUtility
			error "No opened documents." number 1240
		end if
		return missing value
	end if
	
	set a_texdoc to TeXDocController's make_with(a_tex_file, EditorClient's text_encoding())
	if a_tex_file is missing value then
		a_texdoc's set_filename(EditorClient's document_name())
	end if
	return a_texdoc
end texdoc_for_firstdoc

on checkmifiles given saving:savingFlag, autosave:autosaveFlag
	--log "start checkmifiles"
	
	set a_texdoc to texdoc_for_firstdoc with showing_message and need_file
	if a_texdoc is missing value then return
	
	a_texdoc's set_doc_position(EditorClient's index_current_paragraph())
	(* find header commands *)
	set ith to 1
	repeat
		set theParagraph to EditorClient's paragraph_at_index(ith)
		if theParagraph starts with "%" then
			try
				a_texdoc's lookup_header_command(theParagraph)
			on error errMsg number errno
				if errno is in {1220, 1230} then
					EditorClient's show_message(errMsg)
				end if
				error errMsg number errno
			end try
		else
			exit repeat
		end if
		set ith to ith + 1
	end repeat
	--log "after parse header commands"
	
	if savingFlag then
		if EditorClient's is_modified() then
			if not autosaveFlag then
				if not EditorClient's save_with_asking(localized string "DocumentIsModified_AskSave") then
					return
				end if
			else
				EditorClient's save_document()
			end if
		end if
	end if
	--log "end of checkmifiles"
	return a_texdoc
end checkmifiles

on prepare_typeset()
	--log "start prepare_typeset"	
	set a_texdoc to checkmifiles with saving and autosave
	--log "end of checkmifiles in prepare_typeset"
	if not (a_texdoc's check_logfile()) then
		set a_path to a_texdoc's logfile()'s posix_path()
		set a_msg to UtilityHandlers's localized_string("LogFileIsOpened", {a_path})
		EditorClient's show_message(a_msg)
		return missing value
	end if
	--log "end of prepare_typeset"
	return a_texdoc
end prepare_typeset

on prepareVIewErrorLog(theLogFileParser, a_dvi)
	using terms from application "mi"
		try
			set auxFileRef to (path_for_suffix(".aux") of theLogFileParser) as alias
			
			tell application "Finder"
				ignoring application responses
					set creator type of auxFileRef to "MMKE"
					set file type of auxFileRef to "TEXT"
				end ignoring
			end tell
		end try
		
	end using terms from
end prepareVIewErrorLog

(* end: intaract with mi and prepare typesetting and parsing log file ====================================*)

(* execute tex commands called from tools from mi  ====================================*)
on newLogFileParser(a_texdoc)
	--log "start newLogFileParser"
	a_texdoc's logfile()'s set_types("MMKE", "TEXT")
	return LogFileParser's make_with(a_texdoc)
end newLogFileParser

on do_typeset()
	--log "start do_typeset"
	try
		set a_texdoc to prepare_typeset()
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "do_typeset", errMsg) of MessageUtility
		end if
		return missing value
	end try
	if a_texdoc is missing value then
		return missing value
	end if
	showStatusMessage("Typeseting...") of ToolPaletteController
	try
		set a_dvi to typeset() of a_texdoc
	on error number 1250
		return missing value
	end try
	set theLogFileParser to newLogFileParser(a_texdoc)
	showStatusMessage("Analyzing log text ...") of ToolPaletteController
	parseLogFile() of theLogFileParser
	set autoMultiTypeset to contents of default entry "AutoMultiTypeset" of user defaults
	if (autoMultiTypeset and (theLogFileParser's labels_changed())) then
		showStatusMessage("Typeseting...") of ToolPaletteController
		try
			set a_dvi to typeset() of a_texdoc
		on error number 1250
			return missing value
		end try
		showStatusMessage("Analyzing log text ...") of ToolPaletteController
		parseLogFile() of theLogFileParser
	end if
	
	prepareVIewErrorLog(theLogFileParser, a_dvi)
	--viewErrorLog(theLogFileParser, "latex")
	rebuildLabelsFromAux(a_texdoc) of RefPanelController
	showStatusMessage("") of ToolPaletteController
	if (isDviOutput() of theLogFileParser) then
		return a_dvi
	else
		set theMessage to localized string "DVIisNotGenerated"
		showMessage(theMessage) of MessageUtility
		return missing value
	end if
end do_typeset

on logParseOnly()
	--log "start logParseOnly"
	set a_texdoc to prepare_typeset()
	a_texdoc's check_logfile()
	set theLogFileParser to newLogFileParser(a_texdoc)
	parseLogFile() of theLogFileParser
end logParseOnly

on preview_dvi_for_frontdoc()
	--log "start preview_dvi_for_frontdoc"
	set front_doc to make FrontDocument
	set a_file to document_alias() of front_doc
	set a_xfile to XFile's make_with(a_file)
	if a_xfile's path_extension() is ".dvi" then
		return true
	end if
	
	set dvi_file to a_xfile's change_path_extension(".dvi")
	if not dvi_file's item_exists() then
		return false
	end if
	
	set a_dvi to DVIController's make_with_xfile(dvi_file)
	--log "before open dvi"
	try
		openDVI of a_dvi with activation
	on error errMsg number errNum
		showError(errNum, "preview_dvi_for_frontdoc", errMsg) of MessageUtility
	end try
	--log "end preview_dvi_for_frontdoc"
	return true
end preview_dvi_for_frontdoc

on preview_dvi()
	--log "start preview_dvi"
	if not EditorClient's is_frontmost() then
		if preview_dvi_for_frontdoc() then return
	end if
	
	try
		set a_texdoc to checkmifiles without saving and autosave
		a_texdoc's set_use_term(false)
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "preview_dvi", errMsg) of MessageUtility
		end if
		return
	end try
	--log "before lookup_dvi"
	showStatusMessage("Opening DVI file ...") of ToolPaletteController
	set a_dvi to a_texdoc's lookup_dvi()
	--log "before openDVI"
	if a_dvi is not missing value then
		try
			openDVI of a_dvi with activation
		on error errMsg number errNum
			showError(errNum, "preview_dvi", errMsg) of MessageUtility
		end try
	else
		set dviName to name_for_suffix(".dvi") of a_texdoc
		set a_msg to UtilityHandlers's localized_string("DviFileIsNotFound", {dviName})
		EditorClient's show_message(a_msg)
	end if
	--log "end preview_dvi"
end preview_dvi

on preview_pdf()
	
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "preview_dvi", errMsg) of MessageUtility
		end if
		return
	end try
	showStatusMessage("Opening PDF file ...") of ToolPaletteController
	set a_pdf to PDFController's make_with(a_texdoc)
	a_pdf's setup()
	if isExistPDF() of a_pdf then
		openPDFFile() of a_pdf
	else
		EditorClient's show_message(localized string "noPDFfile")
	end if
end preview_pdf

on quick_typeset_preview()
	--log "start quick_typeset_preview"
	try
		set a_texdoc to prepare_typeset()
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then -- "The document is not saved."
			showError(errNum, "quick_typeset_preview after calling prepare_typeset", errMsg) of MessageUtility
		end if
		return
	end try
	
	if a_texdoc is missing value then
		return
	end if
	
	a_texdoc's set_use_term(false)
	--log "before texCompile in quick_typeset_preview"
	showStatusMessage("Typeseting...") of ToolPaletteController
	try
		set a_dvi to typeset() of a_texdoc
	on error number 1250
		return
	end try
	--log "after texCompile in quick_typeset_preview"
	showStatusMessage("Analyzing log text ...") of ToolPaletteController
	set theLogFileParser to newLogFileParser(a_texdoc)
	--log "befor parseLogText in quick_typeset_preview"
	parseLogText() of theLogFileParser
	--log "after parseLogText in quick_typeset_preview"
	showStatusMessage("Opening DVI file  ...") of ToolPaletteController
	set aFlag to isNoError() of theLogFileParser
	if isDviOutput() of theLogFileParser then
		try
			openDVI of a_dvi given activation:aFlag
		on error errMsg number errNum
			showError(errNum, "quick_typeset_preview after calling openDVI", errMsg) of MessageUtility
		end try
	else
		set theMessage to localized string "DVIisNotGenerated"
		showMessage(theMessage) of MessageUtility
	end if
	
	if not aFlag then
		set logManager to call method "sharedLogManager" of class "LogWindowController"
		call method "bringToFront" of logManager
		activate
	end if
	
	--log "before prepareVIewErrorLog"
	--prepareVIewErrorLog(theLogFileParser, a_dvi)
	--viewErrorLog(theLogFileParser, "latex")
	rebuildLabelsFromAux(a_texdoc) of RefPanelController
	showStatusMessage("") of ToolPaletteController
end quick_typeset_preview

on typeset_preview()
	set a_dvi to do_typeset()
	showStatusMessage("Opening DVI file ...") of ToolPaletteController
	if a_dvi is not missing value then
		try
			openDVI of a_dvi given activation:missing value
		on error errMsg number errNum
			showError(errNum, "typeset_preview", errMsg) of MessageUtility
		end try
	end if
end typeset_preview

on typeset_preview_pdf()
	set a_dvi to do_typeset()
	
	if a_dvi is missing value then
		return
	end if
	set a_pdf to dvi_to_pdf() of a_dvi
	showStatusMessage("Opening PDF file ...") of ToolPaletteController
	if a_pdf is missing value then
		set theMessage to localized string "PDFisNotGenerated"
		showMessage(theMessage) of MessageUtility
	else
		openPDFFile() of a_pdf
	end if
end typeset_preview_pdf

on openOutputHadler(an_extension)
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "openOutputHadler", errMsg) of MessageUtility
		end if
		return
	end try
	open_outfile(an_extension) of a_texdoc
end openOutputHadler

on bibtex()
	set bibtexCommand to contents of default entry "bibtexCommand" of user defaults
	execTexCommand(bibtexCommand, "", true)
end bibtex

on dvi_from_editor()
	--log "start dvi_from_editor"
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dvi_to_pdf", errMsg) of MessageUtility
		end if
		return
	end try
	
	set a_dvi to lookup_dvi() of a_texdoc
	if a_dvi is missing value then
		set dviName to a_texdoc's name_for_suffix(".dvi")
		set a_msg to UtilityHandlers's localized_string("DviFileIsNotFound", {dviName})
		EditorClient's show_message(a_msg)
	end if
	
	--log "end dvi_from_editor"
	return a_dvi
end dvi_from_editor

on dvi_from_mxdvi()
	--log "start dvi_from_mxdvi"
	set fileURL to missing value
	tell application "System Events"
		tell process "Mxdvi"
			set n_wind to count windows
			repeat with ith from 1 to (count windows)
				tell window ith
					if (subrole of it is "AXStandardWindow") then
						set fileURL to (value of attribute "AxDocument" of it)
						exit repeat
					end if
				end tell
			end repeat
		end tell
	end tell
	if fileURL is missing value then
		return missing value
	end if
	set theURL to call method "URLWithString:" of class "NSURL" with parameter fileURL
	set thePath to call method "path" of theURL
	set a_texdoc to TeXDocController's make_with_dvifile(thePath)
	set a_dvi to lookup_dvi() of a_texdoc
	return a_dvi
end dvi_from_mxdvi

on dvi_to_pdf()
	--log "start dvi_to_pdf"
	showStatusMessage("Converting DVI to PDF ...") of ToolPaletteController
	set front_app to (path to frontmost application as Unicode text)
	--log appName
	if front_app ends with "Mxdvi.app:" then
		set a_dvi to dvi_from_mxdvi()
	else
		set a_dvi to missing value
		--set a_dvi to dvi_from_mxdvi()
	end if
	
	if a_dvi is missing value then
		set a_dvi to dvi_from_editor()
	end if
	
	if a_dvi is missing value then
		return
	end if
	
	set a_pdf to dvi_to_pdf() of a_dvi
	--log "success to get PDFController"
	if a_pdf is missing value then
		EditorClient's show_message(localized string "PDFisNotGenerated")
	else
		openPDFFile() of a_pdf
	end if
end dvi_to_pdf

on dvi_to_ps()
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dvi_to_ps", errMsg) of MessageUtility
		end if
		return
	end try
	showStatusMessage("Converting DVI to PDF ...") of ToolPaletteController
	if dvipsCommand of a_texdoc is not missing value then
		set theCommand to dvipsCommand of a_texdoc
	else
		set theCommand to contents of default entry "dvipsCommand" of user defaults
	end if
	
	set cdCommand to "cd " & (quoted form of (a_texdoc's pwd()'s posix_path()))
	set theCommand to buildCommand(theCommand, ".dvi") of a_texdoc
	set allCommand to cdCommand & comDelim & theCommand
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
end dvi_to_ps

--simply execute TeX command in Terminal
on execTexCommand(texCommand, theSuffix, checkSaved)
	try
		set a_texdoc to checkmifiles without autosave given saving:checkSaved
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "execTexCommand", errMsg) of MessageUtility
		end if
		return
	end try
	
	set cdCommand to "cd " & (quoted form of (a_texdoc's pwd()'s posix_path()))
	set texCommand to buildCommand(texCommand, theSuffix) of a_texdoc
	set allCommand to cdCommand & comDelim & texCommand
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
end execTexCommand

on seek_ebb()
	set graphicCommand to _backslash & "includegraphics"
	
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "seek_ebb", errMsg) of MessageUtility
		end if
		return
	end try
	
	--set theOriginPath to POSIX path of (a_texdoc's file_ref())
	set theOriginPath to (a_texdoc's file_ref()'s posix_path())
	set_base_path(theOriginPath) of PathConverter
	set graphicExtensions to {".pdf", ".jpg", ".jpeg", ".png"}
	
	set theRes to EditorClient's document_content()
	
	--find graphic files
	set noGraphicFlag to true
	set noNewBBFlag to true
	repeat with ith from 1 to (count paragraph of theRes)
		set theParagraph to paragraph ith of theRes
		if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
			set graphicFile to extractFilePath(graphicCommand, theParagraph) of EditCommands
			repeat with an_extension in graphicExtensions
				if graphicFile ends with an_extension then
					set noGraphicFlag to false
					if execEbb(graphicFile, an_extension) then
						set noNewBBFlag to false
					end if
					exit repeat
				end if
			end repeat
		end if
	end repeat
	
	if noGraphicFlag then
		set a_msg to UtilityHandlers's localized_string("noGraphicFile", {a_texdoc's fileName()})
		EditorClient's show_message(a_msg)
	else if noNewBBFlag then
		EditorClient's show_message(localized string "bbAlreadyCreated")
	end if
end seek_ebb

on execEbb(theGraphicPath, an_extension)
	set basepath to text 1 thru -((length of an_extension) + 1) of theGraphicPath
	set bbPath to basepath & ".bb"
	if isExists(POSIX file bbPath) of UtilityHandlers then
		set bbAlias to POSIX file bbPath as alias
		set graphicAlias to POSIX file theGraphicPath as alias
		tell application "System Events"
			set bbModDate to modification date of bbAlias
			set graphicModDate to modification date of graphicAlias
		end tell
		if (graphicModDate < bbModDate) then
			return false
		end if
	end if
	-------do ebb
	set theGraphicPath to quoted form of theGraphicPath
	set targetDir to dirname(theGraphicPath) of ShellUtils
	set fileName to basename(theGraphicPath, "") of ShellUtils
	set cdCommand to "cd '" & targetDir & "'"
	set ebbCommand to contents of default entry "ebbCommand" of user defaults
	set allCommand to cdCommand & comDelim & ebbCommand & space & "'" & fileName & "'"
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
	copy TerminalCommander to currentTerminal
	waitEndOfCommand(300) of currentTerminal
	return true
end execEbb

on mendex()
	--log "start execmendex"
	set mendexCommand to contents of default entry "mendexCommand" of user defaults
	execTexCommand(mendexCommand, ".idx", false)
end mendex