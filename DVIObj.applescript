global UtilityHandlers
global TerminalCommander
global PDFObj

global comDelim
global texCommandsBox

property dvipdfmxCommand : "/usr/local/bin/dvipdfmx"
property dviViewCommand : "xdvi"

property usexdvi : false
property dviPreviewBox : missing value

on setSettingToWindow()
	tell matrix "Commands" of texCommandsBox
		set contents of cell "dvipdfmx" to dvipdfmxCommand
	end tell
	
	tell dviPreviewBox
		set contents of text field "dviViewCommand" to dviViewCommand
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
	set dvipdfmxCommand to readDefaultValue("dvipdfmx", dvipdfmxCommand) of UtilityHandlers
	
	--DVI Previewer
	set usexdvi to readDefaultValue("UseXdvi", usexdvi) of UtilityHandlers
	set dviViewCommand to readDefaultValue("dviView", dviViewCommand) of UtilityHandlers
end loadSettings

on writeSettings()
	tell user defaults
		--commands
		set contents of default entry "dvipdfmx" to dvipdfmxCommand
		--DVI previewer
		set contents of default entry "dviView" to dviViewCommand
		set contents of default entry "UseXdvi" to usexdvi
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	tell matrix "Commands" of texCommandsBox
		set dvipdfmxCommand to contents of cell "dvipdfmx"
	end tell
	
	tell dviPreviewBox
		set dviViewCommand to contents of text field "dviViewCommand"
		set usexdvi to ((state of cell "UseXdvi" of matrix "PreviewerMode") is on state)
	end tell
	
	writeSettings()
end saveSettingsFromWindow

on makeObj(theTexDocObj)
	script dviObj
		property parent : theTexDocObj
		property dviFileRef : missing value
		property isSrcSpecial : missing value
		
		on getModDate()
			return modification date of (info for dviFileRef)
			(*tell application "System Events"
				return modification date of dviFileRef
			end tell
			*)
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
				doCommands of TerminalCommander for allCommand without activation
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
end makeObj