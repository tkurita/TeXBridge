global EditCommands
global UtilityHandlers
global LogFileParser
global MessageUtility
global PDFObj
global TexDocObj

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

global texCommandsBox

property ebbCommand : "/usr/local/bin/ebb"
property bibtexCommand : "/usr/local/bin/jbibtex"
property dvipsCommand : "/usr/local/bin/dvips"
property mendexCommand : "/usr/local/bin/mendex"

property ignoringErrorList : {1200, 1210, 1220, 1230, 1240}

on setSettingToWindow()
	tell matrix "Commands" of texCommandsBox
		set contents of cell "ebb" to ebbCommand
		set contents of cell "bibtex" to bibtexCommand
		set contents of cell "dvips" to dvipsCommand
		set contents of cell "mendex" to mendexCommand
	end tell
	
end setSettingToWindow

on loadSettings()
	--commands
	set dvipsCommand to readDefaultValue("dvips", dvipsCommand) of UtilityHandlers
	set ebbCommand to readDefaultValue("ebb", ebbCommand) of UtilityHandlers
	set bibtexCommand to readDefaultValue("bibtex", bibtexCommand) of UtilityHandlers
	set mendexCommand to readDefaultValue("mendex", mendexCommand) of UtilityHandlers
end loadSettings

on writeSettings()
	tell user defaults
		--commands
		set contents of default entry "dvips" to dvipsCommand
		set contents of default entry "ebb" to ebbCommand
		set contents of default entry "bibtex" to bibtexCommand
		set contents of default entry "mendex" to mendexCommand
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	tell matrix "Commands" of texCommandsBox
		set ebbCommand to contents of cell "ebb"
		set bibtexCommand to contents of cell "bibtex"
		set dvipsCommand to contents of cell "dvips"
		set mendexCommand to contents of cell "mendex"
	end tell
	
	writeSettings()
end saveSettingsFromWindow

on resolveParentFile(theParagraph)
	--log "start resolveParentFile"
	set parentFile to text 13 thru -2 of theParagraph
	--log parentFile
	if parentFile starts with ":" then
		setHFSoriginPath(parentFile) of PathConverter
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
	
	return theTexFile
end resolveParentFile

on checkmifiles given saving:savingFlag
	--log "start checkmifiles"
	set textADocument to localized string "aDocument"
	
	try
		tell application "mi"
			tell document 1
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
		tell application "mi"
			set docname to name of document 1
		end tell
		set textIsNotSaved to localized string "isNotSaved"
		set theMessage to textADocument & space & sQ & docname & eQ & space & textIsNotSaved
		showMessageOnmi(theMessage) of MessageUtility
		error "The document is not saved." number 1200
	end try
	
	--log "before makeObj of TexDocObj"
	set theTexDocObj to makeObj(theTargetFile) of TexDocObj
	--log "success makeObj of TexDocObj"
	set targetParagraph of theTexDocObj to theParagraph
	
	--check ParentFile and TypesetCommand
	set theParentFile to missing value
	set theTypesetCommand to missing value
	set ith to 1
	repeat
		tell application "mi"
			set theParagraph to paragraph ith of document 1
		end tell
		if theParagraph starts with "%" then
			if theParagraph starts with "%ParentFile" then
				set theParentFile to resolveParentFile(theParagraph)
			else if theParagraph starts with "%TypesetCommand" then
				set theTypesetCommand to text 17 thru -2 of theParagraph
			end if
		else
			exit repeat
		end if
		set ith to ith + 1
	end repeat
	
	if theParentFile is not missing value then
		setTexFileRef(theParentFile) of theTexDocObj
	end if
	
	if theTypesetCommand is not missing value then
		set texCommand of theTexDocObj to theTypesetCommand
	end if
	
	if savingFlag then
		set textDoYouSave to localized string "doYouSave"
		set textIsModified to localized string "isModified"
		
		tell application "mi"
			if modified of document 1 then
				set docname to name of document 1
				try
					set theResult to display dialog textADocument & space & sQ & docname & eQ & space & textIsModified & return & textDoYouSave with icon note
					-- if canceld, error number -128
				on error errMsg number -128
					error "The documen is modified. Saving the document is canceld by user." number 1210
				end try
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
	
	set theTexDocObj to checkmifiles with saving
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
	set theLogFile to logFileRef of theTexDocObj
	set theLogFile to theLogFile as alias
	set logFileRef of theTexDocObj to theLogFile
	
	tell application "Finder"
		ignoring application responses
			set creator type of theLogFile to "MMKE"
			set file type of theLogFile to "TEXT"
		end ignoring
	end tell
	
	return makeObj(theTexDocObj) of LogFileParser
end newLogFileParser

on doTypeSet()
	--log "start doTypeset"
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then
			showError(errNum, errMsg) of MessageUtility
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
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	viewErrorLog(theLogFileParser, "latex")
	updateReferencePalette(theTexDocObj)
	return theDviObj
end doTypeSet

on dviPreview()
	try
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
		return
	end try
	set theDviObj to lookUpDviFile() of theTexDocObj
	if theDviObj is not missing value then
		openDVI() of theDviObj
	else
		set textDviFile to localized string "dviFile"
		set isNotFound to localized string "isNotFound"
		set dviName to getNameWithSuffix(".dvi") of theTexDocObj
		set theMessage to textDviFile & space & dviName & space & isNotFound
		showMessageOnmi(theMessage) of MessageUtility
	end if
end dviPreview

on updateReferencePalette(theTexDocObj)
	try
		tell user defaults
			set visibleRefPalette to contents of default entry "visibleRefPalette"
		end tell
	on error
		return
	end try
	if visibleRefPalette then
		tell main bundle
			set refPalettePath to path for resource "ReferencePalette" extension "app"
		end tell
		set theFileRef to texFileRef of theTexDocObj
		--log "call rebuildLabelsFromAux"
		tell application ((POSIX file refPalettePath) as Unicode text)
			ignoring application responses
				open {commandID:"rebuildLabelsFromAux", argument:theFileRef}
			end ignoring
		end tell
	end if
end updateReferencePalette

on quickTypesetAndPreview()
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in ignoringErrorList then -- "The document is not saved."
			showError(errNum, errMsg) of MessageUtility
		end if
		return
	end try
	
	if theTexDocObj is missing value then
		return
	end if
	
	set compileInTerminal of theTexDocObj to false
	try
		set theDviObj to texCompile() of theTexDocObj
	on error number 1250
		return
	end try
	
	if theDviObj is not missing value then
		openDVI() of theDviObj
	end if
	
	set theLogFileParser to newLogFileParser(theTexDocObj)
	parseLogFile() of theLogFileParser
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	viewErrorLog(theLogFileParser, "latex")
	updateReferencePalette(theTexDocObj)
end quickTypesetAndPreview

on typesetAndPreview()
	set theDviObj to doTypeSet()
	
	if theDviObj is not missing value then
		openDVI() of theDviObj
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
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
		return
	end try
	openOutputFile(theExtension) of theTexDocObj
end openOutputHadler

on bibTex()
	execTexCommand(bibtexCommand, "", true)
end bibTex

on dviToPDF()
	try
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
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
	execTexCommand(dvipsCommand, ".dvi", false)
end dviToPS

--simply execute TeX command in Terminal
on execTexCommand(texCommand, theSuffix, checkSaved)
	try
		set theTexDocObj to checkmifiles given saving:checkSaved
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220, 1230} then
			error errMsg number errNum
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
		set theTexDocObj to checkmifiles without saving
	on error errMsg number errNum
		if errNum is not in {1220, 1230} then
			error errMsg number errNum
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
	waitEndOfCommand(300) of TerminalCommander
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
