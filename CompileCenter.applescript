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
				set a_msg to UtilityHandlers's localized_string("invalidMode", {docname})
				showMessage(a_msg) of MessageUtility
				error "The mode of the document is not supported." number 1205
			end if
			return missing value
		end if
	else
		if message_flag then
			set a_msg to localized string "noDocument"
			showMessage(a_msg) of MessageUtility
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
			on error msg number errno
				if errno is in {1220, 1230} then
					EditorClient's show_message(msg)
				end if
				error msg number errno
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

(* execute tex commands called from tools from mi  ====================================*)
on newLogFileParser(a_texdoc)
	--log "start newLogFileParser"
	a_texdoc's logfile()'s set_types("MMKE", "TEXT")
	return LogFileParser's make_with(a_texdoc)
end newLogFileParser

on logParseOnly()
	--log "start logParseOnly"
	set a_texdoc to prepare_typeset()
	a_texdoc's check_logfile()
	set a_log_file_parser to newLogFileParser(a_texdoc)
	parseLogFile() of a_log_file_parser
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
		open_dvi of a_dvi with activation
	on error msg number errno
		showError(errno, "preview_dvi_for_frontdoc", msg) of MessageUtility
	end try
	--log "end preview_dvi_for_frontdoc"
	return true
end preview_dvi_for_frontdoc

on openOutputHadler(an_extension)
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "openOutputHadler", msg) of MessageUtility
		end if
		return
	end try
	open_outfile(an_extension) of a_texdoc
end openOutputHadler

(*== privates *)
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

on prepare_view_errorlog(a_log_file_parser, a_dvi)
	using terms from application "mi"
		try
			set auxFileRef to (path_for_suffix(".aux") of a_log_file_parser) as alias
			
			tell application "Finder"
				ignoring application responses
					set creator type of auxFileRef to "MMKE"
					set file type of auxFileRef to "TEXT"
				end ignoring
			end tell
		end try
		
	end using terms from
end prepare_view_errorlog

on dvi_from_editor()
	--log "start dvi_from_editor"
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "dvi_to_pdf", msg) of MessageUtility
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

(*== actions *)
on dvi_to_pdf(arg)
	--log "start dvi_to_pdf"
	show_status_message("Converting DVI to PDF ...") of ToolPaletteController
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
		open_pdf() of a_pdf
	end if
end dvi_to_pdf

on dvi_to_ps(arg)
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "dvi_to_ps", msg) of MessageUtility
		end if
		return
	end try
	show_status_message("Converting DVI to PDF ...") of ToolPaletteController
	set a_command to a_texdoc's dvips_command()
	set cdCommand to "cd " & (quoted form of (a_texdoc's pwd()'s posix_path()))
	set a_command to buildCommand(a_command, ".dvi") of a_texdoc
	set allCommand to cdCommand & comDelim & a_command
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
end dvi_to_ps

--simply execute TeX command in Terminal
on execTexCommand(texCommand, theSuffix, checkSaved)
	try
		set a_texdoc to checkmifiles without autosave given saving:checkSaved
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "execTexCommand", msg) of MessageUtility
		end if
		return
	end try
	
	set cdCommand to "cd " & (quoted form of (a_texdoc's pwd()'s posix_path()))
	set texCommand to buildCommand(texCommand, theSuffix) of a_texdoc
	set allCommand to cdCommand & comDelim & texCommand
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
end execTexCommand

on seek_ebb(arg)
	set graphicCommand to _backslash & "includegraphics"
	
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "seek_ebb", msg) of MessageUtility
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
		set a_msg to UtilityHandlers's localized_string("noGraphicFile", {a_texdoc's filename()})
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
	set filename to basename(theGraphicPath, "") of ShellUtils
	set cdCommand to "cd '" & targetDir & "'"
	set ebbCommand to contents of default entry "ebbCommand" of user defaults
	set allCommand to cdCommand & comDelim & ebbCommand & space & "'" & filename & "'"
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
	copy TerminalCommander to currentTerminal
	waitEndOfCommand(300) of currentTerminal
	return true
end execEbb

on mendex(arg)
	--log "start execmendex"
	set mendexCommand to contents of default entry "mendexCommand" of user defaults
	execTexCommand(mendexCommand, ".idx", false)
end mendex

on bibtex(arg)
	set bibtexCommand to contents of default entry "bibtexCommand" of user defaults
	execTexCommand(bibtexCommand, "", true)
end bibtex

on quick_typeset_preview(arg)
	--log "start quick_typeset_preview"
	try
		set a_texdoc to prepare_typeset()
	on error msg number errno
		if errno is not in ignoringErrorList then -- "The document is not saved."
			showError(errno, "quick_typeset_preview after calling prepare_typeset", msg) of MessageUtility
		end if
		return
	end try
	
	if a_texdoc is missing value then
		return
	end if
	
	a_texdoc's set_use_term(false)
	--log "before texCompile in quick_typeset_preview"
	show_status_message("Typeseting...") of ToolPaletteController
	try
		set a_dvi to typeset() of a_texdoc
	on error number 1250
		return
	end try
	--log "after texCompile in quick_typeset_preview"
	show_status_message("Analyzing log text ...") of ToolPaletteController
	set a_log_file_parser to newLogFileParser(a_texdoc)
	--log "befor parseLogText in quick_typeset_preview"
	parseLogText() of a_log_file_parser
	--log "after parseLogText in quick_typeset_preview"
	show_status_message("Opening DVI file  ...") of ToolPaletteController
	set aFlag to isNoError() of a_log_file_parser
	if isDviOutput() of a_log_file_parser then
		try
			open_dvi of a_dvi given activation:aFlag
		on error msg number errno
			showError(errno, "quick_typeset_preview after calling open_dvi", msg) of MessageUtility
		end try
	else
		set a_msg to localized string "DVIisNotGenerated"
		showMessage(a_msg) of MessageUtility
	end if
	
	if not aFlag then
		set logManager to call method "sharedLogManager" of class "LogWindowController"
		call method "bringToFront" of logManager
		activate
	end if
	
	--log "before prepare_view_errorlog"
	--prepare_view_errorlog(a_log_file_parser, a_dvi)
	--viewErrorLog(a_log_file_parser, "latex")
	rebuildLabelsFromAux(a_texdoc) of RefPanelController
	show_status_message("") of ToolPaletteController
end quick_typeset_preview

on typeset_preview(arg)
	set a_dvi to do_typeset(arg)
	show_status_message("Opening DVI file ...") of ToolPaletteController
	if a_dvi is not missing value then
		try
			open_dvi of a_dvi given activation:missing value
		on error msg number errno
			showError(errno, "typeset_preview", msg) of MessageUtility
		end try
	end if
end typeset_preview

on typeset_preview_pdf(arg)
	set a_dvi to do_typeset(arg)
	
	if a_dvi is missing value then
		return
	end if
	set a_pdf to dvi_to_pdf(arg) of a_dvi
	show_status_message("Opening PDF file ...") of ToolPaletteController
	if a_pdf is missing value then
		set a_msg to localized string "PDFisNotGenerated"
		showMessage(a_msg) of MessageUtility
	else
		open_pdf() of a_pdf
	end if
end typeset_preview_pdf

on do_typeset(arg)
	--log "start do_typeset"
	try
		set a_texdoc to prepare_typeset()
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "do_typeset", msg) of MessageUtility
		end if
		return missing value
	end try
	if a_texdoc is missing value then
		return missing value
	end if
	show_status_message("Typeseting...") of ToolPaletteController
	try
		set a_dvi to typeset() of a_texdoc
	on error number 1250
		return missing value
	end try
	set a_log_file_parser to newLogFileParser(a_texdoc)
	show_status_message("Analyzing log text ...") of ToolPaletteController
	parseLogFile() of a_log_file_parser
	set autoMultiTypeset to contents of default entry "AutoMultiTypeset" of user defaults
	if (autoMultiTypeset and (a_log_file_parser's labels_changed())) then
		show_status_message("Typeseting...") of ToolPaletteController
		try
			set a_dvi to typeset() of a_texdoc
		on error number 1250
			return missing value
		end try
		show_status_message("Analyzing log text ...") of ToolPaletteController
		parseLogFile() of a_log_file_parser
	end if
	
	prepare_view_errorlog(a_log_file_parser, a_dvi)
	--viewErrorLog(a_log_file_parser, "latex")
	rebuildLabelsFromAux(a_texdoc) of RefPanelController
	show_status_message("") of ToolPaletteController
	if (isDviOutput() of a_log_file_parser) then
		return a_dvi
	else
		set a_msg to localized string "DVIisNotGenerated"
		showMessage(a_msg) of MessageUtility
		return missing value
	end if
end do_typeset

on preview_dvi(arg)
	--log "start preview_dvi"
	if not EditorClient's is_frontmost() then
		if preview_dvi_for_frontdoc() then return
	end if
	
	try
		set a_texdoc to checkmifiles without saving and autosave
		a_texdoc's set_use_term(false)
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "preview_dvi", msg) of MessageUtility
		end if
		return
	end try
	--log "before lookup_dvi"
	show_status_message("Opening DVI file ...") of ToolPaletteController
	set a_dvi to a_texdoc's lookup_dvi()
	--log "before open_dvi"
	if a_dvi is not missing value then
		try
			open_dvi of a_dvi with activation
		on error msg number errno
			showError(errno, "preview_dvi", msg) of MessageUtility
		end try
	else
		set dviName to name_for_suffix(".dvi") of a_texdoc
		set a_msg to UtilityHandlers's localized_string("DviFileIsNotFound", {dviName})
		EditorClient's show_message(a_msg)
	end if
	--log "end preview_dvi"
end preview_dvi

on preview_pdf(arg)
	
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in ignoringErrorList then
			showError(errno, "preview_dvi", msg) of MessageUtility
		end if
		return
	end try
	show_status_message("Opening PDF file ...") of ToolPaletteController
	set a_pdf to PDFController's make_with(a_texdoc)
	a_pdf's setup()
	if file_exists() of a_pdf then
		open_pdf() of a_pdf
	else
		EditorClient's show_message(localized string "noPDFfile")
	end if
end preview_pdf
