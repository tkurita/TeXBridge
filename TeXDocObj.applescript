global PathAnalyzer
global UtilityHandlers
global TerminalCommander
global dviObj

property name : "TeXDocObj"
property defaultTexCommand : "/usr/local/bin/platex -src-specials -interaction=nonstopmode"
property logSuffix : ".log"

global comDelim
global texCommandsBox

on setSettingToWindow()
	tell matrix "Commands" of texCommandsBox
		set contents of cell "latex" to defaultTexCommand
	end tell
end setSettingToWindow

on loadSettings()
	set defaultTexCommand to readDefaultValue("latex", defaultTexCommand) of UtilityHandlers
end loadSettings

on writeSettings()
	tell user defaults
		set contents of default entry "latex" to defaultTexCommand
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	tell matrix "Commands" of texCommandsBox
		set defaultTexCommand to contents of cell "latex"
	end tell
	
	writeSettings()
end saveSettingsFromWindow

on makeObj(theTargetFile)
	set pathRecord to do(theTargetFile) of PathAnalyzer
	
	script TexDocObj
		property texFileRef : theTargetFile -- targetFileRef's ParentFile. if ParentFile does not exists, it's same to targeFileRef
		property texCommand : defaultTexCommand
		property texFileName : name of pathRecord
		property texBasePath : missing value
		property texBaseName : missing value
		
		property targetFileRef : theTargetFile -- a document applied tools. alias class
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
				copy TerminalCommander to currentTerminal
				waitEndOfCommand(300) of currentTerminal
			else
				set allCommand to cdCommand & "; " & texCommand & space & "'" & texFileName & "'"
				try
					do shell script allCommand
				on error errMsg number errNum
					if errNum is in {1, -1700} then
						-- 1:general tex error
						-- -1700: unknown, result can not be accept
					else if errNum is 127 then
						display dialog errMsg
						return missing value
					else
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
				set theDviObj to makeObj(a reference to me) of dviObj
				set dviFileRef of theDviObj to dviFilePath as alias
				return theDviObj
			else
				return missing value
			end if
		end lookUpDviFile
	end script
end makeObj