property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property parent : load script file (LibraryFolder & "LogParseEngine")
property ShellUtils : load script file (LibraryFolder & "ShellUtils")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer")
property TerminalCommander : load script file (LibraryFolder & "TerminalCommander")

property texCommand : "/usr/local/bin/platex -src-specials -interaction=nonstopmode"
property dvipdfmxCommand : "/usr/local/bin/dvipdfmx"
property ebbCommand : "/usr/local/bin/ebb"
property bibtexCommand : "/usr/local/bin/jbibtex"
property dvipsCommand : "/usr/local/bin/dvips"
--property dviViewCommand : "xdvi -editor 'miclient %l %f'"
property dviViewCommand : "xdvi"

property lifeTime : 60 -- minutes
property FreeTime : 0
property isLaunched : false
property logSuffix : ".log"

property usexdvi : false

property dQ : ASCII character 34
property yenmark : ASCII character 92
property comDelim : return

(* events of application*)
on launched theObject
	if not isLaunched then
		loadSettings()
		center window "Setting"
		set isLaunched to true
	end if
	(*debug code*)
	--seekExecEbb()
	--quickTypesetAndPreview()
	--dviToPDF()
	--dviPreview()
	--doTypeSet()
	--openRelatedFile with revealOnly
	--show window "Setting"
	--debug()
	--open "quickTypesetAndPreview"
	--checkmifiles with saving
	(*end of debug code*)
end launched

on open theCommandID
	if not isLaunched then
		loadSettings()
		center window "Setting"
		set isLaunched to true
	end if
	
	if theCommandID is "typesetOnly" then
		doTypeSet()
	else if theCommandID is "typesetAndPreview" then
		typesetAndPreview()
	else if theCommandID is "quickTypesetAndPreview" then
		quickTypesetAndPreview()
	else if theCommandID is "dviPreview" then
		dviPreview()
	else if theCommandID is "bibTex" then
		bibTex()
	else if theCommandID is "dviToPDF" then
		dviToPDF()
	else if theCommandID is "seekExecEbb" then
		seekExecEbb()
	else if theCommandID is "dvips" then
		dviToPS()
	else if theCommandID is "openRelatedFile" then
		openRelatedFile without revealOnly
	else if theCommandID is "revealRelatedFile" then
		openRelatedFile with revealOnly
	else if theCommandID is "openParentFile" then
		openParentFile()
	else if theCommandID is "setting" then
		activate
		show window "Setting"
	else if theCommandID is "Help" then
		call method "showHelp:"
	else if theCommandID starts with "." then
		openOutputHadler(theCommandID)
	end if
	--display dialog theCommandID
	set FreeTime to 0
	return true
end open

on idle theObject
	set FreeTime to FreeTime + 1
	if FreeTime > lifeTime then
		quit
	end if
	return 60
end idle

on setColorsToWindow(theObject)
	tell box "TerminalColors" of box "TerminalSetting" of theObject
		
		if isChangeBackground of TerminalCommander then
			set state of button "BackSwitch" to 1
			set enabled of color well "BackgroundColor" to true
			set enabled of slider "BackTransparency" to true
			set color of color well "BackgroundColor" to backgroundColor of TerminalCommander
			set contents of slider "BackTransparency" to terminalOpaqueness of TerminalCommander
		else
			set state of button "BackSwitch" to 0
			set enabled of color well "BackgroundColor" to false
			set enabled of slider "BackTransparency" to false
		end if
		
		
		if isChangeNormalText of TerminalCommander then
			set state of button "NormalSwitch" to 1
			set enabled of color well "NormalTextColor" to true
			set color of color well "NormalTextColor" to normalTextColor of TerminalCommander
		else
			set state of button "NormalSwitch" to 0
			set enabled of color well "NormalTextColor" to false
		end if
		
		if isChangeBoldText of TerminalCommander then
			set state of button "BoldSwitch" to 1
			set enabled of color well "BoldTextColor" to true
			set color of color well "BoldTextColor" to boldTextColor of TerminalCommander
		else
			set state of button "BoldSwitch" to 0
			set enabled of color well "BoldTextColor" to false
		end if
		
		if isChangeCursor of TerminalCommander then
			set state of button "CursorSwitch" to 1
			set enabled of color well "CursorColor" to true
			set color of color well "CursorColor" to cursorColor of TerminalCommander
		else
			set state of button "CursorSwitch" to 0
			set enabled of color well "CursorColor" to false
		end if
		
		if isChangeSelection of TerminalCommander then
			set state of button "SelectionSwitch" to 1
			set enabled of color well "SelectionColor" to true
			set color of color well "SelectionColor" to selectionColor of TerminalCommander
		else
			set state of button "SelectionSwitch" to 0
			set enabled of color well "SelectionColor" to false
		end if
	end tell
end setColorsToWindow

on will open theObject
	tell theObject
		tell box "TerminalSetting"
			if useLoginShell of TerminalCommander then
				set state of cell "UseLoginShell" of matrix "ShellMode" to on state
				set state of cell "UseCommand" of matrix "ShellMode" to off state
			else
				set state of cell "UseCommand" of matrix "ShellMode" to on state
				set state of cell "UseLoginShell" of matrix "ShellMode" to off state
			end if
			
			set contents of text field "ShellPath" to shellPath of TerminalCommander
			
			if useCtrlVEscapes of TerminalCommander is "YES" then
				set state of button "UseCtrlVEscapes" to 1
			else
				set state of button "UseCtrlVEscapes" to 0
			end if
			
			set contents of text field "ExecutionString" to executionString of TerminalCommander
			
		end tell
		
		tell matrix "Commands" of box "TeXCommands"
			set contents of cell "latex" to texCommand
			set contents of cell "dvipdfmx" to dvipdfmxCommand
			set contents of cell "ebb" to ebbCommand
			set contents of cell "bibtex" to bibtexCommand
			set contents of cell "dvips" to dvipsCommand
		end tell
		
		tell box "DVIPreview"
			set contents of text field "dviViewCommand" to dviViewCommand
			if usexdvi then
				set state of cell "OpenInFinder" of matrix "PreviewerMode" to off state
				set state of cell "UseXdvi" of matrix "PreviewerMode" to on state
			else
				set state of cell "UseXdvi" of matrix "PreviewerMode" to off state
				set state of cell "OpenInFinder" of matrix "PreviewerMode" to on state
			end if
		end tell
		set contents of text field "LifeTime" to lifeTime as integer
	end tell
	setColorsToWindow(theObject)
end will open

on clicked theObject
	set theName to name of theObject
	if theName is "OKButton" then
		saveSettingsFromWindow()
		hide window of theObject
	else if theName is "CancelButton" then
		hide window of theObject
	else if theName is "ApplyColors" then
		getColorSettingsFromWindow()
		set isBusyPermitted of TerminalCommander to true
		if not applyTerminalColors() of TerminalCommander then
			doCommands("echo Test colors") of TerminalCommander
		end if
	else if theName is "RevertColors" then
		loadColorSettings()
		setColorsToWindow(window of theObject)
		set isBusyPermitted of TerminalCommander to true
		if not applyTerminalColors() of TerminalCommander then
			doCommands("echo Test colors") of TerminalCommander
		end if
	else if theName is "Save" then
		saveSettingsFromWindow()
	end if
end clicked

on choose menu item theObject
	set theName to name of theObject
	if theName is "Preference" then
		show window "Setting"
	end if
end choose menu item

(* read and write defaults ===============================================*)
on readDefaultValue(entryName, defaultValue)
	tell user defaults
		if exists default entry entryName then
			return contents of default entry entryName
		else
			make new default entry at end of default entries with properties {name:entryName, contents:defaultValue}
			return defaultValue
		end if
	end tell
end readDefaultValue

on loadColorSettings()
	set isChangeBackground of TerminalCommander to readDefaultValue("IsChangeBackground", true)
	set backgroundColor of TerminalCommander to readDefaultValue("BackgroundColor", {42858, 43841, 65535})
	set terminalOpaqueness of TerminalCommander to readDefaultValue("TerminalOpaqueness", 58100)
	set isChangeNormalText of TerminalCommander to readDefaultValue("IsChangeNormalText", true)
	set normalTextColor of TerminalCommander to readDefaultValue("NormalTextColor", {65535, 65535, 65535})
	set isChangeBoldText of TerminalCommander to readDefaultValue("IsChangeBoldText", false)
	set boldTextColor of TerminalCommander to readDefaultValue("BoldTextColor", {65535, 65535, 65535})
	set isChangeCursor of TerminalCommander to readDefaultValue("IsChangeCursor", false)
	set cursorColor of TerminalCommander to readDefaultValue("CursorColor", {21823, 21823, 21823})
	set isChangeSelection of TerminalCommander to readDefaultValue("IsChangeSelection", false)
	set selectionColor of TerminalCommander to readDefaultValue("SelectionColor", {43690, 43690, 43690})
end loadColorSettings

on loadSettings()
	set customTitle of TerminalCommander to "TeX Console"
	set stringEncoding of TerminalCommander to 4
	set useLoginShell of TerminalCommander to readDefaultValue("UseLoginShell", false)
	set shellPath of TerminalCommander to readDefaultValue("Shell", "/bin/bash")
	set useCtrlVEscapes of TerminalCommander to readDefaultValue("UseCtrlVEscapes", "YES")
	set executionString of TerminalCommander to readDefaultValue("ExecutionString", "source ~/Library/Preferences/mi/mode/TEX/initialize.sh")
	
	--colors
	loadColorSettings()
	
	--commands
	set texCommand to readDefaultValue("latex", texCommand)
	set dvipdfmxCommand to readDefaultValue("dvipdfmx", dvipdfmxCommand)
	set dvipsCommand to readDefaultValue("dvips", dvipsCommand)
	set ebbCommand to readDefaultValue("ebb", ebbCommand)
	set bibtexCommand to readDefaultValue("bibtex", bibtexCommand)
	
	--DVI Previewer
	set usexdvi to readDefaultValue("UseXdvi", usexdvi)
	set dviViewCommand to readDefaultValue("dviView", dviViewCommand)
	
	set lifeTime to readDefaultValue("LifeTime", lifeTime)
	
	--TerminalCommander Setting
	set displayShellPath of TerminalCommander to false
	set displayCustomTitle of TerminalCommander to true
	set displayDevideName of TerminalCommander to true
end loadSettings

on writeSettings()
	tell user defaults
		set contents of default entry "UseLoginShell" to useLoginShell of TerminalCommander
		set contents of default entry "Shell" to shellPath of TerminalCommander
		set contents of default entry "UseCtrlVEscapes" to useCtrlVEscapes of TerminalCommander
		set contents of default entry "ExecutionString" to executionString of TerminalCommander
		--colors
		set contents of default entry "IsChangeBackground" to isChangeBackground of TerminalCommander
		set contents of default entry "BackgroundColor" to backgroundColor of TerminalCommander
		set contents of default entry "TerminalOpaqueness" to terminalOpaqueness of TerminalCommander
		set contents of default entry "IsChangeNormalText" to isChangeNormalText of TerminalCommander
		set contents of default entry "NormalTextColor" to normalTextColor of TerminalCommander
		set contents of default entry "IsChangeBoldText" to isChangeBoldText of TerminalCommander
		set contents of default entry "BoldTextColor" to boldTextColor of TerminalCommander
		set contents of default entry "IsChangeCursor" to isChangeCursor of TerminalCommander
		set contents of default entry "CursorColor" to cursorColor of TerminalCommander
		set contents of default entry "IsChangeSelection" to isChangeSelection of TerminalCommander
		set contents of default entry "SelectionColor" to selectionColor of TerminalCommander
		--commands
		set contents of default entry "latex" to texCommand
		set contents of default entry "dvipdfmx" to dvipdfmxCommand
		set contents of default entry "dvips" to dvipsCommand
		set contents of default entry "ebb" to ebbCommand
		set contents of default entry "bibtex" to bibtexCommand
		set contents of default entry "LifeTime" to lifeTime
		--DVI previewer
		set contents of default entry "dviView" to dviViewCommand
		set contents of default entry "UseXdvi" to usexdvi
	end tell
end writeSettings
(* end : read and write defaults ===============================================*)

(* handlers get values from window ===============================================*)
on saveSettingsFromWindow() -- get all values from and window and save into preference
	tell window "Setting"
		tell box "TerminalSetting"
			set useLoginShell of TerminalCommander to ((state of cell "UseLoginShell" of matrix "ShellMode") is on state)
			set theShellPath to contents of text field "ShellPath"
			if theShellPath is not "" then
				set shellPath of TerminalCommander to theShellPath
			end if
			
			if state of button "UseCtrlVEscapes" is 1 then
				set useCtrlVEscapes of TerminalCommander to "YES"
			else
				set useCtrlVEscapes of TerminalCommander to "NO"
			end if
			
			set executionString of TerminalCommander to contents of text field "ExecutionString"
			
			my getColorSettingsFromWindow()
			
		end tell
		
		tell matrix "Commands" of box "TeXCommands"
			set texCommand to contents of cell "latex"
			set dvipdfmxCommand to contents of cell "dvipdfmx"
			set ebbCommand to contents of cell "ebb"
			set bibtexCommand to contents of cell "bibtex"
			set dvipsCommand to contents of cell "dvips"
		end tell
		
		tell box "DVIPreview"
			set dviViewCommand to contents of text field "dviViewCommand"
			set usexdvi to ((state of cell "UseXdvi" of matrix "PreviewerMode") is on state)
		end tell
		
		set theLifeTime to (contents of text field "LifeTime") as string
		if theLifeTime is not "" then
			set lifeTime to theLifeTime as integer
		end if
	end tell
	
	writeSettings()
end saveSettingsFromWindow

on getColorSettingsFromWindow()
	tell window "Setting"
		tell box "TerminalSetting"
			tell box "TerminalColors"
				set isChangeBackground of TerminalCommander to (state of button "BackSwitch" is 1)
				if isChangeBackground of TerminalCommander then
					set backgroundColor of TerminalCommander to color of color well "BackgroundColor"
					set terminalOpaqueness of TerminalCommander to contents of slider "BackTransparency"
				end if
				
				set isChangeNormalText of TerminalCommander to (state of button "NormalSwitch" is 1)
				if isChangeNormalText of TerminalCommander then
					set normalTextColor of TerminalCommander to color of color well "NormalTextColor"
				end if
				
				set isChangeBoldText of TerminalCommander to (state of button "BoldSwitch" is 1)
				if isChangeBoldText of TerminalCommander then
					set boldTextColor of TerminalCommander to color of color well "BoldTextColor"
				end if
				
				set isChangeCursor of TerminalCommander to (state of button "CursorSwitch" is 1)
				if isChangeCursor of TerminalCommander then
					set cursorColor of TerminalCommander to color of color well "cursorColor"
				end if
				
				set isChangeSelection of TerminalCommander to (state of button "SelectionSwitch" is 1)
				if isChangeSelection of TerminalCommander then
					set selectionColor of TerminalCommander to color of color well "selectionColor"
				end if
			end tell
			
		end tell
		
	end tell
end getColorSettingsFromWindow
(* end: handlers get values from window ===============================================*)

(* intaract with mi and prepare typesetting and parsing log file ===============================*)
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

on showError(errNum, errMsg)
	activate
	set errorLabel to localized string "errorLabel"
	set theMessage to errorLabel & space & errNum & return & errMsg
	display dialog theMessage buttons {"OK"} default button "OK" with icon caution
end showError

on showMessage(theMessage)
	activate
	display dialog theMessage buttons {"OK"} default button "OK" with icon note
end showMessage

on showMessageOnmi(theMessage)
	tell application "mi"
		activate
		display dialog theMessage buttons {"OK"} default button "OK" with icon note
	end tell
end showMessageOnmi

on isExist(filePath)
	try
		filePath as alias
		return true
	on error
		return false
	end try
end isExist

on isRunning(appName)
	tell application "System Events"
		return exists application process appName
	end tell
end isRunning

on newPDFObj(theDviObj)
	script PDFObj
		property parent : theDviObj
		property pdfFileName : missing value
		property pdfPath : missing value
		property pdfAlias : missing value
		property fileInfo : missing value
		property pageNumber : missing value
		property previewerName : missing value
		property isFirstOperation : missing value
		
		on setPDFObj()
			set pdfFileName to getNameWithSuffix(".pdf")
			set pdfPath to (((my workingDirectory) as Unicode text) & pdfFileName)
		end setPDFObj
		
		on prepareDVItoPDF()
			set existsPDFfile to isExist(pdfPath)
			
			if existsPDFfile then
				set isFirstOperation to false
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
					if isRunning(previewerName) then
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
							showMessageOnmi(theMessage)
							return
						end if
					end if
				end if
			else
				set isFirstOperation to true
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

on newDviObj(theTexDocObj)
	script dviObj
		property parent : theTexDocObj
		property dviFileRef : missing value
		property isSrcSpecial : missing value
		global usexdvi
		
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
			if not (isRunning(x11AppName)) then
				tell application x11AppName
					launch
				end tell
			end if
			
			getSrcSpecialFlag()
			set cdCommand to "cd " & (quoted form of POSIX path of my workingDirectory)
			set dviFileName to getNameWithSuffix(".dvi")
			
			if my isSrcSpecial then
				if my isParentFile then
					setPOSIXoriginPath(POSIX path of my texFileRef) of PathConverter of me
					set sourceFile to getRelativePath of (PathConverter of me) for (POSIX path of my targetFileRef)
				else
					set sourceFile to my texFileName
				end if
				
				set allCommand to cdCommand & comDelim & dviViewCommand & " -sourceposition '" & (my targetParagraph) & space & sourceFile & "' '" & dviFileName & "' &"
				doCommands(allCommand) of TerminalCommander
			else
				try
					set pid to do shell script "ps -o pid,command|awk '/xdvi.bin.*" & dviFileName & "$/{print $1}'"
				on error errMsg number 1
					set pid to ""
				end try
				
				if pid is "" then
					set allCommand to cdCommand & comDelim & dviViewCommand & space & "'" & dviFileName & "' &"
					doCommands(allCommand) of TerminalCommander
				else
					set pid to word 1 of pid
					do shell script "kill -USR1" & space & pid --reread
				end if
			end if
			
		end xdviPreview
		
		on dviToPDF()
			set thePDFObj to lookupPDFFile()
			--check busy status of pdf file.
			prepareDVItoPDF() of thePDFObj
			--convert a DVI file into a PDF file
			set cdCommand to "cd" & space & (quoted form of POSIX path of (my workingDirectory))
			set targetFileName to getNameWithSuffix(".dvi")
			set allCommand to cdCommand & comDelim & dvipdfmxCommand & space & "'" & targetFileName & "'"
			
			doCommands(allCommand) of TerminalCommander
			waitEndOfCommand(300) of TerminalCommander
			return thePDFObj
		end dviToPDF
		
		on lookupPDFFile()
			set thePDFObj to newPDFObj(a reference to me)
			setPDFObj() of thePDFObj
			return thePDFObj
		end lookupPDFFile
	end script
end newDviObj

on checkmifiles given saving:savingFlag
	set textADocument to localized string "aDocument"
	set textIsNotSaved to localized string "isNotSaved"
	set textIsNotFound to localized string "isNotFound"
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
			my showMessageOnmi(theMessage)
			error "The document is not saved." number 1200
		end try
		
		set firstLine to paragraph 1 of document 1
		--tell me to log firstLine
		if firstLine starts with "%ParentFile" then
			set parentFileFlag to true
			set parentFile to text 13 thru -2 of firstLine
			--tell me to log parentFile
			if parentFile starts with ":" then
				setHFSoriginPath(theTargetFile) of PathConverter of me
				set theTexFile to getAbsolutePath of (PathConverter of me) for parentFile
			else
				set theTexFile to parentFile
			end if
			--tell me to log "theTexFile : " & theTexFile
			try
				set theTexFile to theTexFile as alias
			on error
				set theMessage to "ParentFile" & space & sQ & theTexFile & eQ & return & textIsNotFound
				my showMessageOnmi(theMessage)
				error "ParentFile is not found." number 1220
			end try
		else
			set theTexFile to theTargetFile
			set parentFileFlag to false
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
	set pathRecord to do(theTexFile) of PathAnalyzer
	--set theTexFileName to name of pathRecord
	
	script TexDocObj
		property texFileRef : theTexFile
		property texFileName : name of pathRecord
		property texBasePath : missing value
		property texBaseName : missing value
		
		property targetFileRef : theTargetFile
		property targetParagraph : theParagraph
		
		property logFileRef : missing value
		property workingDirectory : folderReference of pathRecord
		property isParentFile : parentFileFlag
		property isSrcSpecial : missing value
		property compileInTerminal : true
		
		property texSuffixList : {".tex", ".dtx"}
		
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
			if isExist(theLogFile) then
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
				doCommands(allCommand) of TerminalCommander
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
			if isExist(dviFilePath) then
				set theDviObj to newDviObj(a reference to me)
				set dviFileRef of theDviObj to dviFilePath as alias
				return theDviObj
			else
				return missing value
			end if
		end lookUpDviFile
	end script
	
	return TexDocObj
end checkmifiles

on prepareTypeSet()
	set textALogfile to localized string "aLogfile"
	set textHasBeenOpend to localized string "hasBeenOpend"
	set textCloseBeforeTypeset to localized string "saveBeforeTypeset"
	set sQ to localized string "startQuote"
	set eQ to localized string "endQuote"
	
	set theTexDocObj to checkmifiles with saving
	--log "end of checkmi"
	
	if not checkLogFileStatus() of theTexDocObj then
		set theMessage to textALogfile & return & sQ & (logFileRef of theTexDocObj) & eQ & return & textHasBeenOpend & return & textCloseBeforeTypeset
		showMessageOnmi(theMessage)
		return missing value
	end if
	return theTexDocObj
end prepareTypeSet

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
on doTypeSet()
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220} then
			showError(errNum, errMsg)
		end if
		return missing value
	end try
	
	if theTexDocObj is missing value then
		return missing value
	end if
	
	set theDviObj to texCompile() of theTexDocObj
	set theLogFileParser to my prepareLogParsing(theTexDocObj)
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
		showMessageOnmi(theMessage)
	end if
end dviPreview

on quickTypesetAndPreview()
	try
		set theTexDocObj to prepareTypeSet()
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220} then -- "The document is not saved."
			showError(errNum, errMsg)
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
	
	set theLogFileParser to my prepareLogParsing(theTexDocObj)
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
		showMessageOnmi(theMessage)
		return
	end if
	
	set thePDFObj to dviToPDF() of theDviObj
	
	openPDFFile() of thePDFObj
end dviToPDF

on dviToPS()
	execTexCommand(dvipsCommand, ".dvi", false)
end dviToPS

--simply execute TeX command in Terminal
on execTexCommand(texCommand, theExtension, checkSaved)
	try
		set theTexDocObj to checkmifiles given saving:checkSaved
	on error errMsg number errNum
		if errNum is not in {1200, 1210, 1220} then
			error errMsg number errNum
		end if
		return
	end try
	
	set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory of theTexDocObj))
	set targetFileName to getNameWithSuffix(theExtension) of theTexDocObj
	set allCommand to cdCommand & comDelim & texCommand & space & "'" & targetFileName & "'"
	doCommands(allCommand) of TerminalCommander
end execTexCommand

on seekExecEbb()
	set graphicCommand to yenmark & "includegraphics"
	
	try
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
		return
	end try
	
	set theOriginPath to POSIX path of texFileRef of theTexDocObj
	setPOSIXoriginPath(theOriginPath) of my PathConverter
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
			set graphicFile to extractFilePath(graphicCommand, theParagraph)
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
		set theMessage to aDocument & space & sQ & (texFileName of theTexDocObj) & dQ & space & noGraphicFile
		showMessageOnmi(theMessage)
	else if noNewBBFlag then
		set theMessage to localized string "bbAlreadyCreated"
		showMessageOnmi(theMessage)
	end if
end seekExecEbb

on execEbb(theGraphicPath, theExtension)
	set basePath to text 1 thru -((length of theExtension) + 1) of theGraphicPath
	set bbPath to basePath & ".bb"
	if isExist(POSIX file bbPath) then
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
	doCommands(allCommand) of TerminalCommander
	waitEndOfCommand(300) of TerminalCommander
	return true
end execEbb

on extractFilePath(theCommand, theParagraph)
	if theParagraph contains theCommand then
		set pos0 to offset of theCommand in theParagraph
		set theParagraph to text pos0 thru -1 of theParagraph
		set pos1 to offset of "{" in theParagraph
		set pos2 to offset of "}" in theParagraph
		set thePath to text (pos1 + 1) thru (pos2 - 1) of theParagraph
		set fullPath to getAbsolutePath of (PathConverter of me) for thePath
	else
		set fullPath to ""
	end if
	return fullPath
end extractFilePath

on openRelatedFile given revealOnly:revealFlag
	try
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
		return
	end try
	
	set theOriginPath to POSIX path of texFileRef of theTexDocObj
	setPOSIXoriginPath(theOriginPath) of my PathConverter
	
	set commandList to {yenmark & "includegraphics", yenmark & "input", yenmark & "include"}
	tell application "mi"
		tell document 1
			set firstpara to targetParagraph of theTexDocObj
			set paracount to (count paragraphs of selection object 1)
			repeat with nth from firstpara to firstpara + paracount - 1
				set theParagraph to paragraph nth
				if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
					repeat with theCommand in commandList
						set fullPath to my extractFilePath(theCommand, theParagraph)
						if fullPath is not "" then
							try
								set fileAlias to (POSIX file fullPath) as alias
							on error
								set fileAlias to (POSIX file (fullPath & ".tex")) as alias
							end try
							if revealFlag then
								tell application "Finder"
									activate
									reveal fileAlias
								end tell
							else
								tell application "Finder" to open fileAlias
							end if
						end if
					end repeat
				end if
			end repeat
		end tell
	end tell
end openRelatedFile

on openParentFile()
	try
		set theTexDocObj to checkmifiles without saving
	on error errMsg number 1200
		return
	end try
	if isParentFile of theTexDocObj then
		tell application "Finder"
			open texFileRef of theTexDocObj
		end tell
	else
		set aDocument to localized string "aDocument"
		set noParentFile to localized string "noParentFile"
		set sQ to localized string "startQuote"
		set eQ to localized string "endQuote"
		set theMessage to aDocument & space & sQ & (texFileName of theTexDocObj) & dQ & space & noParentFile
		showMessageOnmi(theMessage)
	end if
end openParentFile
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
