global EditCommands
global UtilityHandlers
global LogFileParser
global MessageUtility

--general libs
global PathAnalyzer
global ShellUtils
global TerminalCommander
global PathConverter
global PDFObj

--special values
global comDelim
global yenmark

property texCommand : "/usr/local/bin/platex -src-specials -interaction=nonstopmode"
property dvipdfmxCommand : "/usr/local/bin/dvipdfmx"
property ebbCommand : "/usr/local/bin/ebb"
property bibtexCommand : "/usr/local/bin/jbibtex"
property dvipsCommand : "/usr/local/bin/dvips"
property dviViewCommand : "xdvi"

property logSuffix : ".log"
property usexdvi : false
property texCommandsBox : missing value
property dviPreviewBox : missing value

on setSettingToWindow()
	tell matrix "Commands" of texCommandsBox
		set contents of cell "latex" to texCommand
		set contents of cell "dvipdfmx" to dvipdfmxCommand
		set contents of cell "ebb" to ebbCommand
		set contents of cell "bibtex" to bibtexCommand
		set contents of cell "dvips" to dvipsCommand
	end tell
	
	tell dviPreviewBox
		if usexdvi then
			set state of cell "OpenInFinder" of matrix "PreviewerMode" to off state
			set state of cell "UseXdvi" of matrix "PreviewerMode" to on state
		else
			set state of cell "UseXdvi" of matrix "PreviewerMode" to off state
			set state of cell "OpenInFinder" of matrix "PreviewerMode" to on state
		end if
	end tell
end setSettingToWindow

on loadSettings()
	--commands
	set texCommand to readDefaultValue("latex", texCommand) of UtilityHandlers
	set dvipdfmxCommand to readDefaultValue("dvipdfmx", dvipdfmxCommand) of UtilityHandlers
	set dvipsCommand to readDefaultValue("dvips", dvipsCommand) of UtilityHandlers
	set ebbCommand to readDefaultValue("ebb", ebbCommand) of UtilityHandlers
	set bibtexCommand to readDefaultValue("bibtex", bibtexCommand) of UtilityHandlers
	
	--DVI Previewer
	set usexdvi to readDefaultValue("UseXdvi", usexdvi) of UtilityHandlers
	set dviViewCommand to readDefaultValue("dviView", dviViewCommand) of UtilityHandlers
end loadSettings

on writeSettings()
	tell user defaults
		--commands
		set contents of default entry "latex" to texCommand
		set contents of default entry "dvipdfmx" to dvipdfmxCommand
		set contents of default entry "dvips" to dvipsCommand
		set contents of default entry "ebb" to ebbCommand
		set contents of default entry "bibtex" to bibtexCommand
		--DVI previewer
		set contents of default entry "dviView" to dviViewCommand
		set contents of default entry "UseXdvi" to usexdvi
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	tell matrix "Commands" of texCommandsBox
		set texCommand to contents of cell "latex"
		set dvipdfmxCommand to contents of cell "dvipdfmx"
		set ebbCommand to contents of cell "ebb"
		set bibtexCommand to contents of cell "bibtex"
		set dvipsCommand to contents of cell "dvips"
	end tell
	
	tell dviPreviewBox
		set dviViewCommand to contents of text field "dviViewCommand"
		set usexdvi to ((state of cell "UseXdvi" of matrix "PreviewerMode") is on state)
	end tell
	
	writeSettings()
end saveSettingsFromWindow

(*
on newPDFObj(theDviObj)
	script PDFObj
		property parent : theDviObj
		property pdfFileName : missing value
		property pdfPath : missing value
		property pdfAlias : missing value
		property fileInfo : missing value
		property pageNumber : missing value
		property previewerName : missing value
		
		on setPDFObj()
			set pdfFileName to getNameWithSuffix(".pdf")
			set pdfPath to (((my workingDirectory) as Unicode text) & pdfFileName)
		end setPDFObj
		
		on isExistPDF()
			return isExists(pdfPath) of UtilityHandlers
		end isExistPDF
		
		on prepareDVItoPDF()
			set pdfAlias to alias pdfPath
			set fileInfo to info for pdfAlias
			set defAppPath to (default application of fileInfo) as Unicode text
			if defAppPath ends with "Acrobat 6.0 Standard.app:" then
				set previewerName to "Acrobat"
			else if defAppPath ends with "Acrobat 6.0 Professional.app:" then
				set previewerName to "Acrobat"
			else if defAppPath ends with "Acrobat 6.0 Elements.app:" then
				set previewerName to "Acrobat"
			else if defAppPath ends with "Acrobat 5.0" then
				set previewerName to "Acrobat 5.0"
			else
				set previewerName to missing value
			end if
			
			if previewerName is not missing value then
				if isRunning(previewerName) of UtilityHandlers then
					closePDFfile()
				else
					set pageNumber to missing value
				end if
			else
				set isPDFBusy to busy status of fileInfo
				if isPDFBusy then
					try
						tell application (default application of fileInfo as Unicode text)
							close window pdfFileName
						end tell
						set isPDFBusy to busy status of (info for pdfAlias)
					end try
					
					if isPDFBusy then
						set openedMessage to localized string "OpenedMessage"
						set theMessage to pdfPath & return & openedMessage
						showMessageOnmi(theMessage) of MessageUtility
						return
					end if
				end if
			end if
		end prepareDVItoPDF
		
		on closePDFfile()
			set pageNumber to missing value
			using terms from application "Acrobat 6.0 Standard"
				tell application previewerName
					if exists document pdfFileName then
						set theFileAliasPath to file alias of document pdfFileName as Unicode text
						if theFileAliasPath is (pdfAlias as Unicode text) then
							bring to front document pdfFileName
							set pageNumber to page number of PDF Window 1
							close PDF Window 1
						end if
					else
						set pageNumber to missing value
					end if
				end tell
			end using terms from
		end closePDFfile
		
		on openPDFFile()
			openOutputFile(".pdf")
			if pageNumber is not missing value then
				using terms from application "Acrobat 6.0 Standard"
					tell application previewerName
						set page number of PDF Window 1 to pageNumber
					end tell
				end using terms from
			end if
		end openPDFFile
	end script
	
	return PDFObj
end newPDFObj
*)

on newDviObj(theTexDocObj)
	script dviObj
		property parent : theTexDocObj
		property dviFileRef : missing value
		property isSrcSpecial : missing value
		
		on getModDate()
			tell application "System Events"
				return modification date of dviFileRef
			end tell
		end getModDate
		
		on setSrcSpecialFlag()
			if texCommand contains "-src" then
				set my isSrcSpecial to true
				tell application "Finder"
					set comment of (dviFileRef) to "Source Specials"
				end tell
			else
				set my isSrcSpecial to false
				tell application "Finder"
					set comment of dviFileRef to ""
				end tell
			end if
		end setSrcSpecialFlag
		
		on getSrcSpecialFlag()
			if my isSrcSpecial is missing value then
				tell application "Finder"
					set theComment to comment of (dviFileRef)
				end tell
				set isSrcSpecial to (theComment starts with "Source Special")
			end if
		end getSrcSpecialFlag
		
		on openDVI()
			if usexdvi then
				xdviPreview()
			else
				openOutputFile(".dvi")
			end if
		end openDVI
		
		on xdviPreview()
			set x11AppName to "X11"
			if not (isRunning(x11AppName) of UtilityHandlers) then
				tell application x11AppName
					launch
				end tell
			end if
			
			getSrcSpecialFlag()
			set cdCommand to "cd " & (quoted form of POSIX path of my workingDirectory)
			set dviFileName to getNameWithSuffix(".dvi")
			
			if my isSrcSpecial then
				if my hasParentFile then
					setPOSIXoriginPath(POSIX path of my texFileRef) of PathConverter
					set sourceFile to getRelativePath of PathConverter for (POSIX path of my targetFileRef)
				else
					set sourceFile to my texFileName
				end if
				
				set allCommand to cdCommand & comDelim & dviViewCommand & " -sourceposition '" & (my targetParagraph) & space & sourceFile & "' '" & dviFileName & "' &"
				doCommands of TerminalCommander for allCommand with activation
			else
				try
					set pid to do shell script "ps -o pid,command|awk '/xdvi.bin.*" & dviFileName & "$/{print $1}'"
				on error errMsg number 1
					set pid to ""
				end try
				
				if pid is "" then
					set allCommand to cdCommand & comDelim & dviViewCommand & space & "'" & dviFileName & "' &"
					doCommands of TerminalCommander for allCommand with activation
				else
					set pid to word 1 of pid
					do shell script "kill -USR1" & space & pid --reread
				end if
			end if
			
		end xdviPreview
		
		on dviToPDF()
			set thePDFObj to lookupPDFFile()
			--check busy status of pdf file.
			if thePDFObj is not missing value then
				if not prepareDVItoPDF() of thePDFObj then
					return missing value
				end if
			end if
			
			--convert a DVI file into a PDF file
			set cdCommand to "cd" & space & (quoted form of POSIX path of (my workingDirectory))
			set targetFileName to getNameWithSuffix(".dvi")
			set allCommand to cdCommand & comDelim & dvipdfmxCommand & space & "'" & targetFileName & "'"
			
			doCommands of TerminalCommander for allCommand with activation
			waitEndOfCommand(300) of TerminalCommander
			
			if thePDFObj is missing value then
				set thePDFObj to lookupPDFFile()
			else
				if not (isExistPDF() of thePDFObj) then
					set thePDFObj to missing value
				end if
			end if
			
			return thePDFObj
		end dviToPDF
		
		on lookupPDFFile()
			set thePDFObj to makeObj(a reference to me) of PDFObj
			setPDFObj() of thePDFObj
			if isExistPDF() of thePDFObj then
				return thePDFObj
			else
				return missing value
			end if
		end lookupPDFFile
	end script
end newDviObj

on newTexDocObj(theTargetFile)
	set pathRecord to do(theTargetFile) of PathAnalyzer
	
	script TexDocObj
		property texFileRef : theTargetFile -- targetFileRef's ParentFile. if ParentFile does not exists, it's same to targeFileRef
		property texFileName : name of pathRecord
		property texBasePath : missing value
		property texBaseName : missing value
		
		property targetFileRef : theTargetFile -- a document applied tools
		property targetParagraph : missing value
		
		property logFileRef : missing value
		property workingDirectory : folderReference of pathRecord -- if ParentFile exists, it's directory of ParentFile
		property hasParentFile : false
		property isSrcSpecial : missing value
		property compileInTerminal : true
		
		property texSuffixList : {".tex", ".dtx"}
		
		on setTexFileRef(theTexFile) -- set parent file of targetFileRef
			set hasParentFile to true
			set texFileRef to theTexFile
			set pathRecord to do(theTexFile) of PathAnalyzer
			set workingDirectory to folderReference of pathRecord
			set texFileName to name of pathRecord
		end setTexFileRef
		
		on getNameWithSuffix(theSuffix)
			set theBaseName to getBaseName()
			return theBaseName & theSuffix
		end getNameWithSuffix
		
		on getBaseName()
			if texBaseName is missing value then
				set texBaseName to texFileName as Unicode text
				set texBaseName to removeSuffix(texBaseName)
			end if
			return texBaseName
		end getBaseName
		
		on getPathWithSuffix(theSuffix)
			if texBasePath is missing value then
				set texBasePath to texFileRef as Unicode text
				set texBasePath to removeSuffix(texBasePath)
			end if
			return texBasePath & theSuffix
		end getPathWithSuffix
		
		on removeSuffix(theText)
			repeat with ith from 1 to length of texSuffixList
				set theSuffix to item ith of texSuffixList
				if theText ends with theSuffix then
					set suffixLength to length of theSuffix
					set theText to text 1 thru (-1 * (suffixLength + 1)) of theText
					exit repeat
				end if
			end repeat
			return theText
		end removeSuffix
		
		on checkLogFileStatus()
			set textALogfile to localized string "aLogfile"
			set textHasBeenOpend to localized string "hasBeenOpend"
			set textShouldClose to localized string "shouldClose"
			set textCancel to localized string "Cancel"
			set textClose to localized string "Close"
			
			set theLogFile to getPathWithSuffix(logSuffix)
			set logFileReady to false
			if isExists(theLogFile) of UtilityHandlers then
				if busy status of (info for file theLogFile) then
					tell application "mi"
						set nDoc to count document
						repeat with ith from 1 to nDoc
							set theFilePath to file of document ith as Unicode text
							if theFilePath is theLogFile then
								try
									set theResult to display dialog textALogfile & return & theLogFile & return & textHasBeenOpend & return & textShouldClose buttons {textCancel, textClose} default button textClose with icon note
								on error errMsg number -128 --if canceld, error number -128
									set logFileReady to false
									exit repeat
								end try
								
								if button returned of theResult is textClose then
									close document ith without saving
									set logFileReady to true
									exit repeat
								end if
							end if
						end repeat
					end tell
				else
					set logFileReady to true
				end if
			else
				set logFileReady to true
			end if
			
			if logFileReady then
				set logFileRef to theLogFile
			end if
			return logFileReady
		end checkLogFileStatus
		
		on openOutputFile(theExtension)
			set ouputFilePath to getPathWithSuffix(theExtension)
			try
				tell application "Finder"
					open (ouputFilePath as alias)
				end tell
			on error errMsg number errNum
				activate
				display dialog errMsg buttons {"OK"} default button "OK"
			end try
		end openOutputFile
		
		on texCompile()
			set beforeCompileTime to current date
			set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory))
			
			set allCommand to cdCommand & comDelim & texCommand & space & "'" & texFileName & "'"
			
			if compileInTerminal then
				set allCommand to cdCommand & comDelim & texCommand & space & "'" & texFileName & "'"
				doCommands of TerminalCommander for allCommand with activation
				waitEndOfCommand(300) of TerminalCommander
			else
				set allCommand to cdCommand & "; " & texCommand & space & "'" & texFileName & "'"
				try
					do shell script allCommand
				on error errMsg number errNum
					if errNum is not in {1, -1700} then
						-- 1:general tex error
						-- -1700: unknown, result can not be accept
						error errMsg number errNum
					end if
				end try
			end if
			
			set theDviObj to lookUpDviFile()
			if theDviObj is not missing value then
				set dviModDate to getModDate() of theDviObj
				if dviModDate > beforeCompileTime then
					setSrcSpecialFlag() of theDviObj
				else
					set theDviObj to missing value
				end if
			end if
			
			return theDviObj
		end texCompile
		
		on lookUpDviFile()
			set dviFilePath to getPathWithSuffix(".dvi")
			if isExists(dviFilePath) of UtilityHandlers then
				set theDviObj to newDviObj(a reference to me)
				set dviFileRef of theDviObj to dviFilePath as alias
				return theDviObj
			else
				return missing value
			end if
		end lookUpDviFile
	end script
end newTexDocObj

on checkmifiles given saving:savingFlag
	set textADocument to localized string "aDocument"
	set textIsNotSaved to localized string "isNotSaved"
	set textIsNotFound to localized string "isNotFound"
	set textIsInvalid to localized string "isInvalid"
	set sQ to localized string "startQuote"
	set eQ to localized string "endQuote"
	set textIsModified to localized string "isModified"
	set textDoYouSave to localized string "doYouSave"
	
	tell application "mi"
		tell document 1
			set theTargetFile to file
			set theParagraph to index of paragraph 1 of selection object 1
		end tell
		try
			set theTargetFile to theTargetFile as alias
		on error
			set docname to name of document 1
			set theMessage to textADocument & space & sQ & docname & eQ & space & textIsNotSaved
			showMessageOnmi(theMessage) of MessageUtility
			error "The document is not saved." number 1200
		end try
		
		set theTexDocObj to my newTexDocObj(theTargetFile)
		set targetParagraph of theTexDocObj to theParagraph
		
		set firstLine to paragraph 1 of document 1
		--tell me to log firstLine
		if firstLine starts with "%ParentFile" then
			set parentFile to text 13 thru -2 of firstLine
			--tell me to log parentFile
			if parentFile starts with ":" then
				setHFSoriginPath(theTargetFile) of PathConverter
				set theTexFile to getAbsolutePath of PathConverter for parentFile
			else
				set theTexFile to parentFile
			end if
			--tell me to log "theTexFile : " & theTexFile
			
			if theTexFile ends with ":" then
				set theMessage to "ParentFile" & space & sQ & parentFile & eQ & return & textIsInvalid
				showMessageOnmi(theMessage) of MessageUtility
				error "ParentFile is invalid." number 1230
			end if
			
			try
				set theTexFile to theTexFile as alias
			on error
				set theMessage to "ParentFile" & space & sQ & theTexFile & eQ & return & textIsNotFound
				showMessageOnmi(theMessage) of MessageUtility
				error "ParentFile is not found." number 1220
			end try
			
			setTexFileRef(theTexFile) of theTexDocObj
		end if
	end tell
	
	if savingFlag then
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
	
	return theTexDocObj
end checkmifiles

on prepareTypeSet()
	set textALogfile to localized string "aLogfile"
	set textHasBeenOpend to localized string "hasBeenOpend"
	set textCloseBeforeTypeset to localized string "saveBeforeTypeset"
	set sQ to localized string "startQuote"
	set eQ to localized string "endQuote"
	
	set theTexDocObj to checkmifiles with saving
	
	if not checkLogFileStatus() of theTexDocObj then
		set theMessage to textALogfile & return & sQ & (logFileRef of theTexDocObj) & eQ & return & textHasBeenOpend & return & textCloseBeforeTypeset
		showMessageOnmi(theMessage) of MessageUtility
		return missing value
	end if
	return theTexDocObj
end prepareTypeSet

on viewErrorLog(theTexDocObj, hyperlist, theCommand)
	set textGroup to localized string "group"
	set docname to texFileName of theTexDocObj
	if hyperlist is not {} then
		tell application "mi"
			if compileInTerminal of theTexDocObj then
				activate
			end if
			set theDateText to (current date) as string
			if (indexwindow "TeX Compile Log" exists) then
				ignoring application responses
					tell (a reference to (every indexgroup of indexwindow "TeX Compile Log")) to collapse
					
					tell (a reference to indexwindow "TeX Compile Log")
						set index to 1
						make new indexgroup at before first indexgroup with properties {comment:theCommand & " : " & docname & " : " & theDateText, content:hyperlist}
					end tell
				end ignoring
			else
				make new indexwindow with properties {name:"TeX Compile Log", infoorder:2, fileorder:1, filewidth:200, infowidth:500}
				tell (a reference to indexwindow "TeX Compile Log")
					set index to 1
					make new indexgroup at before first indexgroup with properties {comment:theCommand & " : " & docname & " : " & theDateText, content:hyperlist}
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
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220, 1230} then
			showError(errNum, errMsg) of MessageUtility
		end if
		return missing value
	end try
	if theTexDocObj is missing value then
		return missing value
	end if
	set theDviObj to texCompile() of theTexDocObj
	
	set theLogFileParser to newLogFileParser(theTexDocObj)
	activate
	parseLogFile() of theLogFileParser
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	viewErrorLog(theTexDocObj, hyperlist of theLogFileParser, "latex")
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

on quickTypesetAndPreview()
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220, 1230} then -- "The document is not saved."
			showError(errNum, errMsg) of MessageUtility
		end if
		return
	end try
	
	if theTexDocObj is missing value then
		return
	end if
	
	set compileInTerminal of theTexDocObj to false
	set theDviObj to texCompile() of theTexDocObj
	if theDviObj is not missing value then
		openDVI() of theDviObj
	end if
	
	set theLogFileParser to newLogFileParser(theTexDocObj)
	parseLogFile() of theLogFileParser
	prepareVIewErrorLog(theLogFileParser, theDviObj)
	viewErrorLog(theTexDocObj, hyperlist of theLogFileParser, "latex")
	
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
on execTexCommand(texCommand, theExtension, checkSaved)
	try
		set theTexDocObj to checkmifiles given saving:checkSaved
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220, 1230} then
			error errMsg number errNum
		end if
		return
	end try
	
	set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory of theTexDocObj))
	set targetFileName to getNameWithSuffix(theExtension) of theTexDocObj
	set allCommand to cdCommand & comDelim & texCommand & space & "'" & targetFileName & "'"
	doCommands of TerminalCommander for allCommand with activation
end execTexCommand

on seekExecEbb()
	set graphicCommand to yenmark & "includegraphics"
	
	try
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
		return
	end try
	
	set theOriginPath to POSIX path of texFileRef of theTexDocObj
	setPOSIXoriginPath(theOriginPath) of PathConverter
	set graphicExtensions to {".pdf", ".jpg", ".jpeg", "png"}
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