global UtilityHandlers
global TerminalCommander
global PDFObj
global PathConverter
global DefaultsManager

global comDelim

property defaultDVIPDFCommand : "/usr/local/bin/dvipdfmx"
property dviViewCommand : "xdvi"
property DVIPreviewMode : 1

property texCommandsBox : missing value
property dviPreviewBox : missing value

on controlClicked(theObject)
	--log "controlClicked in DViObj"
	set DVIPreviewMode to current row of theObject
	set contents of default entry "DVIPreviewMode" of user defaults to DVIPreviewMode
	setDVIDriver()
end controlClicked

on endEditing(theObject)
	set theName to name of theObject
	set theCommand to contents of contents of theObject
	if theName is "dviViewCommand" then
		set dviViewCommand to theCommand
		set contents of default entry "dviViewCommand" of user defaults to dviViewCommand
	else if theName is "dvipdfCommand" then
		set defaultDVIPDFCommand to theCommand
		set contents of default entry "dvipdfCommand" of user defaults to defaultDVIPDFCommand
	end if
end endEditing

on setSettingToWindow(theViewForCommand, theViewForMode)
	set texCommandsBox to theViewForCommand
	tell matrix "Commands" of texCommandsBox
		set contents of cell "dvipdf" to defaultDVIPDFCommand
	end tell
	
	set dviPreviewBox to theViewForMode
	tell dviPreviewBox
		set contents of text field "dviViewCommand" to dviViewCommand
		set current row of matrix "PreviewerMode" to DVIPreviewMode
	end tell
end setSettingToWindow

on revertToFactorySetting()
	set defaultDVIPDFCommand to getFactorySetting of DefaultsManager for "dvipdfCommand"
	
	--DVI Previewer
	set DVIPreviewMode to (getFactorySetting of DefaultsManager for "DVIPreviewMode") as integer
	set dviViewCommand to getFactorySetting of DefaultsManager for "dviViewCommand"
	
	setDVIDriver()
	writeSettings()
end revertToFactorySetting

on loadSettings()
	--log "start loadSettings of DVIObj"
	--commands
	set defaultDVIPDFCommand to readDefaultValue("dvipdfCommand") of DefaultsManager
	
	--DVI Previewer
	set DVIPreviewMode to (readDefaultValue("DVIPreviewMode") of DefaultsManager) as integer
	set dviViewCommand to readDefaultValue("dviViewCommand") of DefaultsManager
	
	setDVIDriver()
	--log "end of loadSettings of DVIObj"
end loadSettings

on writeSettings()
	tell user defaults
		--commands
		set contents of default entry "dvipdfCommand" to defaultDVIPDFCommand
		--DVI previewer
		set contents of default entry "dviViewCommand" to dviViewCommand
		set contents of default entry "DVIPreviewMode" to DVIPreviewMode
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	tell matrix "Commands" of texCommandsBox
		set defaultDVIPDFCommand to contents of text field "dvipdfCommand"
	end tell
	
	tell dviPreviewBox
		set dviViewCommand to contents of text field "dviViewCommand"
		set DVIPreviewMode to current row of matrix "PreviewerMode"
	end tell
	setDVIDriver()
	writeSettings()
end saveSettingsFromWindow

script XdviDriver
	on openDVI(theDviObj)
		set x11AppName to "X11"
		if not (isRunning(x11AppName) of UtilityHandlers) then
			tell application x11AppName
				launch
			end tell
		end if
		
		getSrcSpecialFlag() of theDviObj
		set cdCommand to "cd " & (quoted form of POSIX path of workingDirectory of theDviObj)
		set dviFileName to getNameWithSuffix(".dvi") of theDviObj
		
		if isSrcSpecial of theDviObj then
			if hasParentFile of theDviObj then
				setPOSIXoriginPath(POSIX path of texFileRef of theDviObj) of PathConverter
				set sourceFile to getRelativePath of PathConverter for (POSIX path of targetFileRef of theDviObj)
			else
				set sourceFile to texFileName of theDviObj
			end if
			
			set allCommand to cdCommand & comDelim & dviViewCommand & " -sourceposition '" & (targetParagraph of theDviObj) & space & sourceFile & "' '" & dviFileName & "' &"
			doCommands of TerminalCommander for allCommand without activation
		else
			try
				set pid to do shell script "ps -o pid,command|awk '/xdvi.bin.*" & dviFileName & "$/{print $1}'"
			on error errMsg number 1
				set pid to ""
			end try
			
			if pid is "" then
				set allCommand to cdCommand & comDelim & dviViewCommand & space & "'" & dviFileName & "' &"
				doCommands of TerminalCommander for allCommand without activation
			else
				set pid to word 1 of pid
				do shell script "kill -USR1" & space & pid --reread
			end if
		end if
	end openDVI
end script

script SimpleDriver
	on openDVI(theDviObj)
		openOutputFile(".dvi") of theDviObj
	end openDVI
end script

script MxdviDriver
	on openDVI(theDviObj)
		--log "start openDVI of MxdviDriver"
		try
			set mxdviApp to path to application "Mxdvi" as alias
		on error
			set theMessage to localized string "mxdviIsnotFound"
			error theMessage number 1260
		end try
		getSrcSpecialFlag() of theDviObj
		--log "success getSrcSpecialFlag"
		if isSrcSpecial of theDviObj then
			set dviFileName to getNameWithSuffix(".dvi") of theDviObj
			--log "success getNameWithSuffix"
			set cdCommand to "cd " & (quoted form of POSIX path of workingDirectory of theDviObj)
			set mxdviPath to quoted form of POSIX path of ((mxdviApp as Unicode text) & "Contents:MacOS:Mxdvi")
			set allCommand to cdCommand & comDelim & mxdviPath & "  -sourceposition " & (targetParagraph of theDviObj) & " '" & dviFileName & "' &"
			doCommands of TerminalCommander for allCommand without activation
		else
			tell application (mxdviApp as Unicode text)
				open dviFileRef of theDviObj
			end tell
		end if
		--log "end openDVI"
	end openDVI
end script


property DVIDriver : SimpleDriver

on setDVIDriver()
	if DVIPreviewMode is 1 then
		set DVIDriver to SimpleDriver
	else if DVIPreviewMode is 2 then
		set DVIDriver to MxdviDriver
	else if DVIPreviewMode is 3 then
		set DVIDriver to XdviDriver
	end if
end setDVIDriver

on makeObj(theTexDocObj)
	if dvipdfCommand of theTexDocObj is missing value then
		set theCommand to defaultDVIPDFCommand
	else
		set theCommand to dvipdfCommand of theTexDocObj
	end if
	
	script dviObj
		property parent : theTexDocObj
		property dviFileRef : missing value
		property isSrcSpecial : missing value
		property dvipdfCommand : theCommand
		
		on getModDate()
			return modification date of (info for dviFileRef)
		end getModDate
		
		on setSrcSpecialFlag()
			if my texCommand contains "-src" then
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
			openDVI(a reference to me) of DVIDriver
		end openDVI
		
		on dviToPDF()
			--log "start dviToPDF"
			set thePDFObj to lookupPDFFile()
			--log "success lookupPDFFile"
			--check busy status of pdf file.
			if thePDFObj is not missing value then
				if not prepareDVItoPDF() of thePDFObj then
					return missing value
				end if
			end if
			
			--log "convert a DVI file into a PDF file"
			set cdCommand to "cd" & space & (quoted form of POSIX path of (my workingDirectory))
			set targetFileName to getNameWithSuffix(".dvi")
			set allCommand to cdCommand & comDelim & dvipdfCommand & space & "'" & targetFileName & "'"
			
			doCommands of TerminalCommander for allCommand with activation
			copy TerminalCommander to currentTerminal
			waitEndOfCommand(300) of currentTerminal
			
			if thePDFObj is missing value then
				set thePDFObj to lookupPDFFile()
			else
				if not (isExistPDF() of thePDFObj) then
					set thePDFObj to missing value
				end if
			end if
			
			--log "end of dviToPDF"
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
end makeObj