global EditCommands
global UtilityHandlers
global LogFileParser
global MessageUtility
global PDFObj
global DviObj
global TexDocObj
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
	
	set a_texdoc to TexDocObj's make_with(a_tex_file, EditorClient's text_encoding())
	if a_tex_file is missing value then
		a_texdoc's set_filename(EditorClient's document_name())
	end if
	return a_texdoc
end texdoc_for_firstdoc

on checkmifiles given saving:savingFlag, autosave:autosaveFlag
	--log "start checkmifiles"
	
	(*
	try
		tell application "mi"
			tell document 1
				set docname to name
				if mode is not in supportedMode then
					set a_message to UtilityHandlers's localized_string("invalidMode", {docname})
					showMessage(a_message) of MessageUtility
					error "The mode of the document is not supported." number 1205
				end if
				set theTargetFile to file
				set theParagraph to index of paragraph 1 of selection object 1
			end tell
		end tell
	on error errMsg number -1728
		set theMessage to localized string "noDocument"
		showMessage(theMessage) of MessageUtility
		error "No opened documents." number 1240
	end try
	
	try
		set theTargetFile to theTargetFile as alias
	on error
		set a_message to UtilityHandlers's localized_string("DocumentIsNotSaved", {docname})
		showMessageOnmi(a_message) of MessageUtility
		error "The document is not saved." number 1200
	end try
	
	--log "before makeObj of TexDocObj"
	set theTexDocObj to TexDocObj's make_with(theTargetFile, EditorClient's text_encoding())
	--log "success make of TexDocObj"
	*)
	set theTexDocObj to texdoc_for_firstdoc with showing_message and need_file
	if theTexDocObj is missing value then return
	
	set targetParagraph of theTexDocObj to theParagraph
	(* find header commands *)
	set ith to 1
	repeat
		set theParagraph to EditorClient's paragraph_at_index(ith)
		if theParagraph starts with "%" then
			try
				theTexDocObj's lookup_header_command(theParagraph)
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
		set textDoYouSave to localized string "doYouSave"
		set textIsModified to localized string "isModified"
		set textADocument to localized string "aDocument"
		
		tell application "mi"
			if modified of document 1 then
				if not autosaveFlag then
					set docname to name of document 1
					try
						set theResult to display dialog textADocument & space & sQ & docname & eQ & space & textIsModified & return & textDoYouSave with icon note
						-- if canceld, error number -128
					on error errMsg number -128
						error "The documen is modified. Saving the document is canceld by user." number 1210
					end try
				end if
				save document 1
			end if
		end tell
	end if
	--log "end of checkmifiles"
	return theTexDocObj
end checkmifiles

on prepareTypeSet()
	--log "start prepareTypeSet"
	set textALogfile to localized string "aLogfile"
	set textHasBeenOpend to localized string "hasBeenOpend"
	set textCloseBeforeTypeset to localized string "saveBeforeTypeset"
	set sQ to localized string "startQuote"
	set eQ to localized string "endQuote"
	
	set theTexDocObj to checkmifiles with saving and autosave
	--log "end of checkmifiles in prepareTypeSet"
	if not (theTexDocObj's check_logfile()) then
		set a_path to theTexDocObj's logfile()'s hfs_path()
		set theMessage to textALogfile & return & sQ & a_path & eQ & return & textHasBeenOpend & return & textCloseBeforeTypeset
		showMessageOnmi(theMessage) of MessageUtility
		return missing value
	end if
	--log "end of prepareTypeSet"
	return theTexDocObj
end prepareTypeSet

on prepareVIewErrorLog(theLogFileParser, theDviObj)
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

on doTypeSet()
	--log "start doTypeset"
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "doTypeSet", errMsg) of MessageUtility
		end if
		return missing value
	end try
	if theTexDocObj is missing value then
		return missing value
	end if
	showStatusMessage("Typeseting...") of ToolPaletteController
	try
		set theDviObj to typeset() of theTexDocObj
	on error number 1250
		return missing value
	end try
	set theLogFileParser to newLogFileParser(theTexDocObj)
	showStatusMessage("Analyzing log text ...") of ToolPaletteController
	parseLogFile() of theLogFileParser
	set autoMultiTypeset to contents of default entry "AutoMultiTypeset" of user defaults
	if (autoMultiTypeset and (theLogFileParser's labels_changed())) then
		showStatusMessage("Typeseting...") of ToolPaletteController
		try
			set theDviObj to typeset() of theTexDocObj
		on error number 1250
			return missing value
		end try
		showStatusMessage("Analyzing log text ...") of ToolPaletteController
		parseLogFile() of theLogFileParser
	end if
	
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	--viewErrorLog(theLogFileParser, "latex")
	rebuildLabelsFromAux(theTexDocObj) of RefPanelController
	showStatusMessage("") of ToolPaletteController
	if (isDviOutput() of theLogFileParser) then
		return theDviObj
	else
		set theMessage to localized string "DVIisNotGenerated"
		showMessage(theMessage) of MessageUtility
		return missing value
	end if
end doTypeSet

on logParseOnly()
	--log "start logParseOnly"
	set theTexDocObj to prepareTypeSet()
	theTexDocObj's check_logfile()
	set theLogFileParser to newLogFileParser(theTexDocObj)
	parseLogFile() of theLogFileParser
end logParseOnly

on dviPreview()
	--log "start dviPreview"
	try
		set theTexDocObj to checkmifiles without saving and autosave
		theTexDocObj's set_use_term(false)
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dviPreview", errMsg) of MessageUtility
		end if
		return
	end try
	--log "before lookup_dvi"
	showStatusMessage("Opening DVI file ...") of ToolPaletteController
	set theDviObj to lookup_dvi() of theTexDocObj
	--log "before openDVI"
	if theDviObj is not missing value then
		try
			openDVI of theDviObj with activation
		on error errMsg number errNum
			showError(errNum, "dviPreview", errMsg) of MessageUtility
		end try
	else
		set textDviFile to localized string "dviFile"
		set isNotFound to localized string "isNotFound"
		set dviName to name_for_suffix(".dvi") of theTexDocObj
		set theMessage to textDviFile & space & dviName & space & isNotFound
		showMessageOnmi(theMessage) of MessageUtility
	end if
	--log "end dviPreview"
end dviPreview

on pdfPreview()
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dviPreview", errMsg) of MessageUtility
		end if
		return
	end try
	showStatusMessage("Opening PDF file ...") of ToolPaletteController
	set thePDFObj to makeObj(theTexDocObj) of PDFObj
	setPDFObj() of thePDFObj
	if isExistPDF() of thePDFObj then
		openPDFFile() of thePDFObj
	else
		set theMessage to localized string "noPDFfile"
		showMessageOnmi(theMessage) of MessageUtility
	end if
end pdfPreview

on quickTypesetAndPreview()
	--log "start quickTypesetAndPreview"
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then -- "The document is not saved."
			showError(errNum, "quickTypesetAndPreview after calling prepareTypeSet", errMsg) of MessageUtility
		end if
		return
	end try
	
	if theTexDocObj is missing value then
		return
	end if
	
	theTexDocObj's set_use_term(false)
	--log "before texCompile in quickTypesetAndPreview"
	showStatusMessage("Typeseting...") of ToolPaletteController
	try
		set theDviObj to typeset() of theTexDocObj
	on error number 1250
		return
	end try
	--log "after texCompile in quickTypesetAndPreview"
	showStatusMessage("Analyzing log text ...") of ToolPaletteController
	set theLogFileParser to newLogFileParser(theTexDocObj)
	--log "befor parseLogText in quickTypesetAndPreview"
	parseLogText() of theLogFileParser
	--log "after parseLogText in quickTypesetAndPreview"
	showStatusMessage("Opening DVI file  ...") of ToolPaletteController
	set aFlag to isNoError() of theLogFileParser
	if isDviOutput() of theLogFileParser then
		try
			openDVI of theDviObj given activation:aFlag
		on error errMsg number errNum
			showError(errNum, "quickTypesetAndPreview after calling openDVI", errMsg) of MessageUtility
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
	--prepareVIewErrorLog(theLogFileParser, theDviObj)
	--viewErrorLog(theLogFileParser, "latex")
	rebuildLabelsFromAux(theTexDocObj) of RefPanelController
	showStatusMessage("") of ToolPaletteController
end quickTypesetAndPreview

on typesetAndPreview()
	set theDviObj to doTypeSet()
	showStatusMessage("Opening DVI file ...") of ToolPaletteController
	if theDviObj is not missing value then
		try
			openDVI of theDviObj given activation:missing value
		on error errMsg number errNum
			showError(errNum, "typesetAndPreview", errMsg) of MessageUtility
		end try
	end if
end typesetAndPreview

on typesetAndPDFPreview()
	set theDviObj to doTypeSet()
	
	if theDviObj is missing value then
		return
	end if
	set thePDFObj to dviToPDF() of theDviObj
	showStatusMessage("Opening PDF file ...") of ToolPaletteController
	if thePDFObj is missing value then
		set theMessage to localized string "PDFisNotGenerated"
		showMessage(theMessage) of MessageUtility
	else
		openPDFFile() of thePDFObj
	end if
end typesetAndPDFPreview

on openOutputHadler(an_extension)
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "openOutputHadler", errMsg) of MessageUtility
		end if
		return
	end try
	open_outfile(an_extension) of theTexDocObj
end openOutputHadler

on bibTex()
	set bibtexCommand to contents of default entry "bibtexCommand" of user defaults
	execTexCommand(bibtexCommand, "", true)
end bibTex

on lookUpDviFromEditor()
	--log "start lookUpDviFromEditor"
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dviToPDF", errMsg) of MessageUtility
		end if
		return
	end try
	
	set theDviObj to lookup_dvi() of theTexDocObj
	if theDviObj is missing value then
		set textDviFile to localized string "dviFile"
		set isNotFound to localized string "isNotFound"
		set dviName to theTexDocObj's name_for_suffix(".dvi")
		set theMessage to textDviFile & space & dviName & space & isNotFound
		showMessageOnmi(theMessage) of MessageUtility
	end if
	
	--log "end lookUpDviFromEditor"
	return theDviObj
end lookUpDviFromEditor

on lookUpDviFromMxdvi()
	--log "start lookUpDviFromMxdvi"
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
	set theTexDocObj to TexDocObj's make_with_dvifile(thePath)
	set theDviObj to lookup_dvi() of theTexDocObj
	return theDviObj
end lookUpDviFromMxdvi

on dviToPDF()
	--log "start dviToPDF"
	showStatusMessage("Converting DVI to PDF ...") of ToolPaletteController
	set appName to (path to frontmost application as Unicode text)
	--log appName
	if appName ends with "Mxdvi.app:" then
		set theDviObj to lookUpDviFromMxdvi()
	else
		set theDviObj to missing value
		--set theDviObj to lookUpDviFromMxdvi()
	end if
	
	if theDviObj is missing value then
		set theDviObj to lookUpDviFromEditor()
	end if
	
	if theDviObj is missing value then
		return
	end if
	
	set thePDFObj to dviToPDF() of theDviObj
	--log "success to get PDFObj"
	if thePDFObj is missing value then
		set theMessage to localized string "PDFisNotGenerated"
		showMessageOnmi(theMessage) of MessageUtility
	else
		openPDFFile() of thePDFObj
	end if
end dviToPDF

on dviToPS()
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dviToPS", errMsg) of MessageUtility
		end if
		return
	end try
	showStatusMessage("Converting DVI to PDF ...") of ToolPaletteController
	if dvipsCommand of theTexDocObj is not missing value then
		set theCommand to dvipsCommand of theTexDocObj
	else
		set theCommand to contents of default entry "dvipsCommand" of user defaults
	end if
	
	--set cdCommand to "cd " & (quoted form of POSIX path of (theTexDocObj's pwd()))
	set cdCommand to "cd " & (quoted form of (theTexDocObj's pwd()'s posix_path()))
	set theCommand to buildCommand(theCommand, ".dvi") of theTexDocObj
	set allCommand to cdCommand & comDelim & theCommand
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
end dviToPS

--simply execute TeX command in Terminal
on execTexCommand(texCommand, theSuffix, checkSaved)
	try
		set theTexDocObj to checkmifiles without autosave given saving:checkSaved
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "execTexCommand", errMsg) of MessageUtility
		end if
		return
	end try
	
	--set cdCommand to "cd " & (quoted form of POSIX path of (theTexDocObj's pwd()))
	set cdCommand to "cd " & (quoted form of (theTexDocObj's pwd()'s posix_path()))
	set texCommand to buildCommand(texCommand, theSuffix) of theTexDocObj
	set allCommand to cdCommand & comDelim & texCommand
	--doCommands of TerminalCommander for allCommand with activation
	sendCommands of TerminalCommander for allCommand
end execTexCommand

on seekExecEbb()
	set graphicCommand to _backslash & "includegraphics"
	
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "seekExecEbb", errMsg) of MessageUtility
		end if
		return
	end try
	
	--set theOriginPath to POSIX path of (theTexDocObj's file_ref())
	set theOriginPath to (theTexDocObj's file_ref()'s posix_path())
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
		set aDocument to localized string "aDocument"
		set sQ to localized string "startQuote"
		set eQ to localized string "endQuote"
		set noGraphicFile to localized string "noGraphicFile"
		set theMessage to aDocument & space & sQ & (theTexDocObj's fileName()) & eQ & space & noGraphicFile
		showMessageOnmi(theMessage) of MessageUtility
	else if noNewBBFlag then
		set theMessage to localized string "bbAlreadyCreated"
		showMessageOnmi(theMessage) of MessageUtility
	end if
end seekExecEbb

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

on execmendex()
	--log "start execmendex"
	set mendexCommand to contents of default entry "mendexCommand" of user defaults
	execTexCommand(mendexCommand, ".idx", false)
end execmendex
