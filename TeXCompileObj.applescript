global EditCommands
global UtilityHandlers
global LogFileParser
global MessageUtility
global PDFObj
global TexDocObj
global DefaultsManager

--general libs
global PathAnalyzer
global ShellUtils
global TerminalCommander
global PathConverter

--special values
global comDelim
global yenmark
global sQ -- start of quotation character
global eQ -- end of quotation character

property texCommandsBox : missing value

property ebbCommand : "/usr/local/bin/ebb"
property bibtexCommand : "/usr/local/bin/jbibtex"
property dvipsCommand : "/usr/local/bin/dvips"
property mendexCommand : "/usr/local/bin/mendex"

property ignoringErrorList : {1200, 1205, 1210, 1220, 1230, 1240}
property supportedMode : {"TEX", "LaTeX"}
property visibleRefPalette : false
property autoMultiTypeset : false

on controlClicked(theObject)
	set theName to name of theObject
	if theName is "AutoMultiTypeset" then
		set autoMultiTypeset to (state of theObject is 1)
		tell user defaults
			set contents of default entry "AutoMultiTypeset" to autoMultiTypeset
		end tell
	end if
end controlClicked

on endEditing(theObject)
	set theName to name of theObject
	set theContents to contents of contents of theObject
	if theName is "dvipsCommand" then
		set dvipsCommand to theContents
	else if theName is "ebbCommand" then
		set ebbCommand to theContents
	else if theName is "bibtexCommand" then
		set bibtexCommand to theContents
	else if theName is "mendexCommand" then
		set mendexCommand to theContents
	end if
	set contents of default entry theName of user defaults to theContents
end endEditing

on setSettingToWindow(theView)
	set texCommandsBox to theView
	tell texCommandsBox
		set contents of text field "ebbCommand" to ebbCommand
		set contents of text field "bibtexCommand" to bibtexCommand
		set contents of text field "dvipsCommand" to dvipsCommand
		set contents of text field "mendexCommand" to mendexCommand
	end tell
end setSettingToWindow

on revertToFactorySetting()
	--log "start revertToFactorySetting in TeXCompileServer"
	set dvipsCommand to getFactorySetting of DefaultsManager for "dvipsCommand"
	set ebbCommand to getFactorySetting of DefaultsManager for "ebbCommand"
	set bibtexCommand to getFactorySetting of DefaultsManager for "bibtexCommand"
	set mendexCommand to getFactorySetting of DefaultsManager for "mendexCommand"
	writeSettings()
	--log "end revertToFactorySetting in TeXCompileServer"
end revertToFactorySetting

on loadSettings()
	set dvipsCommand to readDefaultValue("dvipsCommand") of DefaultsManager
	set ebbCommand to readDefaultValue("ebbCommand") of DefaultsManager
	set bibtexCommand to readDefaultValue("bibtexCommand") of DefaultsManager
	set mendexCommand to readDefaultValue("mendexCommand") of DefaultsManager
	set visibleRefPalette to readDefaultValueWith("visibleRefPalette", visibleRefPalette) of DefaultsManager
	set autoMultiTypeset to readDefaultValue("AutoMultiTypeset") of DefaultsManager
end loadSettings

on writeSettings()
	tell user defaults
		--commands
		set contents of default entry "dvipsCommand" to dvipsCommand
		set contents of default entry "ebbCommand" to ebbCommand
		set contents of default entry "bibtexCommand" to bibtexCommand
		set contents of default entry "mendexCommand" to mendexCommand
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	tell texCommandsBox
		set ebbCommand to contents of text field "ebb"
		set bibtexCommand to contents of text field "bibtex"
		set dvipsCommand to contents of text field "dvips"
		set mendexCommand to contents of text field "mendex"
	end tell
	
	writeSettings()
end saveSettingsFromWindow

on resolveParentFile(theParagraph, theTargetFile)
	--log "start resolveParentFile"
	set parentFile to stripHeadTailSpaces(text 13 thru -2 of theParagraph) of UtilityHandlers
	--log parentFile
	if parentFile starts with ":" then
		setHFSoriginPath(theTargetFile) of PathConverter
		set theTexFile to getAbsolutePath of PathConverter for parentFile
	else
		set theTexFile to parentFile
	end if
	--tell me to log "theTexFile : " & theTexFile
	
	if theTexFile ends with ":" then
		set textIsInvalid to localized string "isInvalid"
		set theMessage to "ParentFile" & space & sQ & parentFile & eQ & return & textIsInvalid
		showMessageOnmi(theMessage) of MessageUtility
		error "ParentFile is invalid." number 1230
	end if
	
	try
		set theTexFile to theTexFile as alias
	on error
		set textIsNotFound to localized string "isNotFound"
		set theMessage to "ParentFile" & space & sQ & theTexFile & eQ & return & textIsNotFound
		showMessageOnmi(theMessage) of MessageUtility
		error "ParentFile is not found." number 1220
	end try
	
	--log "end resolveParentFile"
	return theTexFile
end resolveParentFile

on checkmifiles given saving:savingFlag, autosave:autosaveFlag
	--log "start checkmifiles"
	set textADocument to localized string "aDocument"
	
	try
		tell application "mi"
			tell document 1
				set docname to name
				if mode is not in supportedMode then
					set theMessage to getLocalizedString of UtilityHandlers given keyword:"invalidMode", insertTexts:{docname}
					showMessage(theMessage) of MessageUtility
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
		set textIsNotSaved to localized string "isNotSaved"
		set theMessage to textADocument & space & sQ & docname & eQ & space & textIsNotSaved
		showMessageOnmi(theMessage) of MessageUtility
		error "The document is not saved." number 1200
	end try
	
	--log "before makeObj of TexDocObj"
	set theTexDocObj to makeObj(theTargetFile) of TexDocObj
	--log "success makeObj of TexDocObj"
	set targetParagraph of theTexDocObj to theParagraph
	
	(* finde header commands *)
	set ith to 1
	repeat
		tell application "mi"
			set theParagraph to paragraph ith of document 1
		end tell
		if theParagraph starts with "%" then
			ignoring case
				if theParagraph starts with "%ParentFile" then
					set theParentFile to resolveParentFile(theParagraph, theTargetFile)
					setTexFileRef(theParentFile) of theTexDocObj
				else if theParagraph starts with "%Typeset-Command" then
					set texCommand of theTexDocObj to stripHeadTailSpaces(text 18 thru -2 of theParagraph) of UtilityHandlers
				else if theParagraph starts with "%DviToPdf-Command" then
					set dvipdfCommand of theTexDocObj to stripHeadTailSpaces(text 19 thru -2 of theParagraph) of UtilityHandlers
				else if theParagraph starts with "%DviToPs-Command" then
					set dvipsCommand of theTexDocObj to stripHeadTailSpaces(text 18 thru -2 of theParagraph) of UtilityHandlers
				end if
			end ignoring
		else
			exit repeat
		end if
		set ith to ith + 1
	end repeat
	
	if savingFlag then
		set textDoYouSave to localized string "doYouSave"
		set textIsModified to localized string "isModified"
		
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
	if not checkLogFileStatus() of theTexDocObj then
		set theMessage to textALogfile & return & sQ & (logFileRef of theTexDocObj) & eQ & return & textHasBeenOpend & return & textCloseBeforeTypeset
		showMessageOnmi(theMessage) of MessageUtility
		return missing value
	end if
	--log "end of prepareTypeSet"
	return theTexDocObj
end prepareTypeSet

on viewErrorLog(theLogFileParser, theCommand)
	set textGroup to localized string "group"
	set docname to texFileName of theLogFileParser
	if hyperlist of theLogFileParser is not {} then
		tell application "mi"
			(*
			if (compileInTerminal of theLogFileParser) or (not (isNoMessages of theLogFileParser)) then
				activate
			end if
			*)
			set theDateText to (current date) as string
			if (indexwindow "TeX Compile Log" exists) then
				ignoring application responses
					tell (a reference to (every indexgroup of indexwindow "TeX Compile Log")) to collapse
					
					tell (a reference to indexwindow "TeX Compile Log")
						set index to 1
						make new indexgroup at before first indexgroup with properties {comment:theCommand & " : " & docname & " : " & theDateText, content:hyperlist of theLogFileParser}
					end tell
				end ignoring
			else
				make new indexwindow with properties {name:"TeX Compile Log", infoorder:2, fileorder:1, filewidth:200, infowidth:500}
				tell (a reference to indexwindow "TeX Compile Log")
					set index to 1
					make new indexgroup at before first indexgroup with properties {comment:theCommand & " : " & docname & " : " & theDateText, content:hyperlist of theLogFileParser}
					repeat while (exists indexgroup textGroup)
						delete indexgroup textGroup
					end repeat
					set asksaving to false
				end tell
			end if
		end tell
	end if
end viewErrorLog

on prepareVIewErrorLog(theLogFileParser, theDviObj)
	using terms from application "mi"
		try
			set auxFileRef to (getPathWithSuffix(".aux") of theLogFileParser) as alias
			set beginning of hyperlist of theLogFileParser to {file:auxFileRef}
			
			tell application "Finder"
				ignoring application responses
					set creator type of auxFileRef to "MMKE"
					set file type of auxFileRef to "TEXT"
				end ignoring
			end tell
		end try
		
		set beginning of hyperlist of theLogFileParser to {file:logFileRef of theLogFileParser}
		if theDviObj is not missing value then
			set beginning of hyperlist of theLogFileParser to {file:dviFileRef of theDviObj}
		end if
	end using terms from
end prepareVIewErrorLog

(* end: intaract with mi and prepare typesetting and parsing log file ====================================*)

(* execute tex commands called from tools from mi  ====================================*)
on newLogFileParser(theTexDocObj)
	--log "start newLogFileParser"
	set theLogFile to logFileRef of theTexDocObj
	set theLogFile to theLogFile as alias
	set logFileRef of theTexDocObj to theLogFile
	
	tell application "Finder"
		ignoring application responses
			set creator type of theLogFile to "MMKE"
			set file type of theLogFile to "TEXT"
		end ignoring
	end tell
	
	--log "end of newLogFileParser"
	return makeObj(theTexDocObj) of LogFileParser
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
	try
		set theDviObj to texCompile() of theTexDocObj
	on error number 1250
		return missing value
	end try
	set theLogFileParser to newLogFileParser(theTexDocObj)
	parseLogFile() of theLogFileParser
	if (autoMultiTypeset and (isLabelsChanged of theLogFileParser)) then
		try
			set theDviObj to texCompile() of theTexDocObj
		on error number 1250
			return missing value
		end try
		parseLogFile() of theLogFileParser
	end if
	
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	viewErrorLog(theLogFileParser, "latex")
	updateReferencePalette(theTexDocObj)
	
	if isDviOutput of theLogFileParser then
		return theDviObj
	else
		return missing value
	end if
end doTypeSet

on logParseOnly()
	--log "start logParseOnly"
	set theTexDocObj to prepareTypeSet()
	checkLogFileStatus() of theTexDocObj
	set theLogFileParser to newLogFileParser(theTexDocObj)
	parseLogFile() of theLogFileParser
end logParseOnly

on dviPreview()
	--log "start dviPreview"
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dviPreview", errMsg) of MessageUtility
		end if
		return
	end try
	--log "before lookUpDviFile"
	set theDviObj to lookUpDviFile() of theTexDocObj
	--log "before openDVI"
	if theDviObj is not missing value then
		try
			openDVI() of theDviObj
		on error errMsg number errNum
			showError(errNum, "dviPreview", errMsg) of MessageUtility
		end try
	else
		set textDviFile to localized string "dviFile"
		set isNotFound to localized string "isNotFound"
		set dviName to getNameWithSuffix(".dvi") of theTexDocObj
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
	
	set thePDFObj to makeObj(theTexDocObj) of PDFObj
	setPDFObj() of thePDFObj
	if isExistPDF() of thePDFObj then
		openPDFFile() of thePDFObj
	else
		set theMessage to localized string "noPDFfile"
		showMessageOnmi(theMessage)
	end if
end pdfPreview

on updateReferencePalette(theTexDocObj)
	--log "start updateReferencePalette"
	if visibleRefPalette then
		tell main bundle
			set refPalettePath to path for resource "ReferencePalette" extension "app"
		end tell
		set theFileRef to texFileRef of theTexDocObj
		--log "theFileRef : " & (theFileRef as Unicode text)
		--log "call rebuildLabelsFromAux"
		tell application ((POSIX file refPalettePath) as Unicode text)
			ignoring application responses
				open {commandID:"rebuildLabelsFromAux", argument:theFileRef}
			end ignoring
		end tell
	else
		--log "rebuildLabesFromAux is not called."
	end if
end updateReferencePalette

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
	
	set compileInTerminal of theTexDocObj to false
	--log "before texCompile in quickTypesetAndPreview"
	try
		set theDviObj to texCompile() of theTexDocObj
	on error number 1250
		return
	end try
	--log "after texCompile in quickTypesetAndPreview"
	
	set theLogFileParser to newLogFileParser(theTexDocObj)
	--log "befor parseLogText in quickTypesetAndPreview"
	parseLogText() of theLogFileParser
	--log "after parseLogText in quickTypesetAndPreview"
	if isDviOutput of theLogFileParser then
		try
			openDVI() of theDviObj
		on error errMsg number errNum
			showError(errNum, "quickTypesetAndPreview after calling openDVI", errMsg) of MessageUtility
		end try
	end if
	
	--log "after openDVI in quickTypesetAndPreview"
	--set theLogFileParser to newLogFileParser(theTexDocObj)
	--log "before parseLogFile in quickTypesetAndPreview"
	--parseLogFile() of theLogFileParser
	--log "after parseLogFile in quickTypesetAndPreview"
	
	--log "before prepareVIewErrorLog"
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	viewErrorLog(theLogFileParser, "latex")
	updateReferencePalette(theTexDocObj)
end quickTypesetAndPreview

on typesetAndPreview()
	set theDviObj to doTypeSet()
	
	if theDviObj is not missing value then
		try
			openDVI() of theDviObj
		on error errMsg number errNum
			showError(errNum, "typesetAndPreview", errMsg) of MessageUtility
		end try
	end if
end typesetAndPreview

on typesetAndPDFPreview()
	set theDviObj to doTypeSet()
	
	if theDviObj is missing value then
		set theMessage to localized string "DVIisNotGenerated"
		showMessageOnmi(theMessage) of MessageUtility
		return
	end if
	
	set thePDFObj to dviToPDF() of theDviObj
	if thePDFObj is missing value then
		set theMessage to localized string "PDFisNotGenerated"
		showMessageOnmi(theMessage) of MessageUtility
	else
		openPDFFile() of thePDFObj
	end if
end typesetAndPDFPreview

on openOutputHadler(theExtension)
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "openOutputHadler", errMsg) of MessageUtility
		end if
		return
	end try
	openOutputFile(theExtension) of theTexDocObj
end openOutputHadler

on bibTex()
	execTexCommand(bibtexCommand, "", true)
end bibTex

on dviToPDF()
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "dviToPDF", errMsg) of MessageUtility
		end if
		return
	end try
	
	set theDviObj to lookUpDviFile() of theTexDocObj
	if theDviObj is missing value then
		set textDviFile to localized string "dviFile"
		set isNotFound to localized string "isNotFound"
		set dviName to getNameWithSuffix(".dvi") of theTexDocObj
		set theMessage to textDviFile & space & dviName & space & isNotFound
		showMessageOnmi(theMessage) of MessageUtility
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
	
	if dvipsCommand of theTexDocObj is not missing value then
		set theCommand to dvipsCommand of theTexDocObj
	else
		set theCommand to dvipsCommand
	end if
	
	set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory of theTexDocObj))
	set theCommand to buildCommand(theCommand, ".dvi") of theTexDocObj
	set allCommand to cdCommand & comDelim & theCommand
	doCommands of TerminalCommander for allCommand with activation
end dviToPS

--simply execute TeX command in Terminal
on execTexCommand(texCommand, theSuffix, checkSaved)
	try
		set theTexDocObj to checkmifiles given saving:checkSaved without autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "execTexCommand", errMsg) of MessageUtility
		end if
		return
	end try
	
	set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory of theTexDocObj))
	set texCommand to buildCommand(texCommand, theSuffix) of theTexDocObj
	set allCommand to cdCommand & comDelim & texCommand
	doCommands of TerminalCommander for allCommand with activation
end execTexCommand

on seekExecEbb()
	set graphicCommand to yenmark & "includegraphics"
	
	try
		set theTexDocObj to checkmifiles without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, "seekExecEbb", errMsg) of MessageUtility
		end if
		return
	end try
	
	set theOriginPath to POSIX path of texFileRef of theTexDocObj
	setPOSIXoriginPath(theOriginPath) of PathConverter
	set graphicExtensions to {".pdf", ".jpg", ".jpeg", ".png"}
	tell application "mi"
		set theRes to content of document 1
	end tell
	
	--find graphic files
	set noGraphicFlag to true
	set noNewBBFlag to true
	repeat with ith from 1 to (count paragraph of theRes)
		set theParagraph to paragraph ith of theRes
		if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
			set graphicFile to extractFilePath(graphicCommand, theParagraph) of EditCommands
			repeat with theExtension in graphicExtensions
				if graphicFile ends with theExtension then
					set noGraphicFlag to false
					if execEbb(graphicFile, theExtension) then
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
		set theMessage to aDocument & space & sQ & (texFileName of theTexDocObj) & eQ & space & noGraphicFile
		showMessageOnmi(theMessage) of MessageUtility
	else if noNewBBFlag then
		set theMessage to localized string "bbAlreadyCreated"
		showMessageOnmi(theMessage) of MessageUtility
	end if
end seekExecEbb

on execEbb(theGraphicPath, theExtension)
	set basePath to text 1 thru -((length of theExtension) + 1) of theGraphicPath
	set bbPath to basePath & ".bb"
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
	set fileName to baseName(theGraphicPath, "") of ShellUtils
	set cdCommand to "cd '" & targetDir & "'"
	set eddCommand to ebbCommand & space & "'" & fileName & "'"
	set allCommand to cdCommand & comDelim & eddCommand
	doCommands of TerminalCommander for allCommand with activation
	copy TerminalCommander to currentTerminal
	waitEndOfCommand(300) of currentTerminal
	return true
end execEbb


on execmendex()
	--log "start execmendex"
	execTexCommand(mendexCommand, ".idx", false)
end execmendex
(* end: execute tex commands called from tools from mi  ====================================*)

(*
on debug()
	copy my LogFileParser to theLogFileParser
	
	script theTexDocObj
		property logFileRef : alias ("IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:テスト:lecture:Lecture.log" as Unicode text)
		property texBasePath : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:テスト:lecture:Lecture"
		property texFileName : "Lecture.tex"
	end script
	
	parseLogFile(theTexDocObj) of theLogFileParser
	
	using terms from application "mi"
		try
			set auxFileRef to (getPathWithSuffix(".aux") of theTexDocObj) as alias
			set beginning of hyperlist of theLogFileParser to {file:auxFileRef}
			
			tell application "Finder"
				ignoring application responses
					set creator type of auxFileRef to "MMKE"
					set file type of auxFileRef to "TEXT"
				end ignoring
			end tell
		end try
		set beginning of hyperlist of theLogFileParser to {file:logFileRef of theTexDocObj}
	end using terms from
	viewErrorLog(texFileName of theTexDocObj, hyperlist of theLogFileParser, "latex")
end debug
*)
