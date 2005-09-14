global PathAnalyzer
global StringEngine
global UtilityHandlers
global TerminalCommander
global MessageUtility
global dviObj
global ToolPaletteController

property name : "TeXDocObj"
property logSuffix : ".log"

global comDelim

on makeObjFromDVIFile(dviFileRef)
	--log "start makeObjFromDVIFile"
	local basePath
	set dviFilePath to dviFileRef as Unicode text
	if dviFilePath ends with ".dvi" then
		set basePath to text 1 thru -5 of dviFilePath
	else
		set basePath to dviFilePath
	end if
	set texFilePath to basePath & ".tex"
	
	if isExists(POSIX file texFilePath) of UtilityHandlers then
		set theTexDocObj to makeObj(POSIX file texFilePath)
		getHeaderCommandFromFile() of theTexDocObj
	else
		set theTexDocObj to makeObj(POSIX file basePath)
	end if
	
	return theTexDocObj
end makeObjFromDVIFile

on makeObj(theTargetFile)
	--log "start makeObj in TexDocObj"
	set pathRecord to do(theTargetFile) of PathAnalyzer
	
	script TexDocObj
		property texFileRef : theTargetFile -- targetFileRef's ParentFile. if ParentFile does not exists, it's same to targeFileRef
		property texCommand : missing value
		property dvipdfCommand : missing value
		property dvipsCommand : missing value
		
		property texFileName : name of pathRecord
		property texBasePath : missing value
		property texBaseName : missing value
		
		property targetFileRef : theTargetFile -- a document applied tools. alias class
		property targetParagraph : missing value
		
		property logFileRef : missing value
		property logContents : missing value
		property workingDirectory : folderReference of pathRecord -- if ParentFile exists, it's directory of ParentFile
		property hasParentFile : false
		property isSrcSpecial : missing value
		property compileInTerminal : true
		
		property texSuffixList : {".tex", ".dtx"}
		
		on getLogContents()
			return logContetns of logContainer
		end getLogContents
		
		on resolveParentFile(theParagraph)
			--log "start resolveParentFile"
			set parentFile to stripHeadTailSpaces(text 13 thru -2 of theParagraph) of UtilityHandlers
			--log parentFile
			if parentFile starts with ":" then
				setHFSoriginPath(targetFileRef) of PathConverter
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
		
		on getHeaderCommand(theParagraph)
			ignoring case
				if theParagraph starts with "%ParentFile" then
					set theParentFile to resolveParentFile(theParagraph)
					setTexFileRef(theParentFile) of theTexDocObj
				else if theParagraph starts with "%Typeset-Command" then
					set my texCommand to stripHeadTailSpaces(text 18 thru -2 of theParagraph) of UtilityHandlers
				else if theParagraph starts with "%DviToPdf-Command" then
					set my dvipdfCommand to stripHeadTailSpaces(text 19 thru -2 of theParagraph) of UtilityHandlers
				else if theParagraph starts with "%DviToPs-Command" then
					set my dvipsCommand to stripHeadTailSpaces(text 18 thru -2 of theParagraph) of UtilityHandlers
				end if
			end ignoring
		end getHeaderCommand
		
		on getHeaderCommandFromFile()
			--log "start getHearderCommandFromFile"
			set lineFeed to ASCII character 10
			set inputFile to open for access texFileRef
			set theParagraph to read inputFile before lineFeed
			repeat while (theParagraph starts with "%")
				getHeaderCommand(theParagraph)
				try
					set theParagraph to read inputFile before lineFeed
				on error
					exit repeat
				end try
			end repeat
			close access inputFile
		end getHeaderCommandFromFile
		
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
		
		on buildCommand(theCommand, theSuffix)
			-- replace %s in theCommand with texBaseName. if %s is not in theCommand, texBaseName+theSuffix is added end of theCommand
			if "%s" is in theCommand then
				set theBaseName to getBaseName()
				startStringEngine() of StringEngine
				set theCommand to uTextReplace of StringEngine for theCommand from "%s" by theBaseName
				stopStringEngine() of StringEngine
				return theCommand
			else
				set targetFileName to getNameWithSuffix(theSuffix)
				return (theCommand & space & "'" & targetFileName & "'")
			end if
		end buildCommand
		
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
			--log "start texCompile"
			set beforeCompileTime to current date
			set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory))
			
			if texCommand is missing value then
				set texCommand to contents of default entry "typesetCommand" of user defaults
			end if
			
			if compileInTerminal then
				set allCommand to cdCommand & comDelim & texCommand & space & "'" & texFileName & "'"
				doCommands of TerminalCommander for allCommand with activation
				copy TerminalCommander to currentTerminal
				delay 1
				waitEndOfCommand(300) of currentTerminal
			else
				startStringEngine() of StringEngine
				set commandElements to everyTextItem of StringEngine from texCommand by space
				if "-interaction=" is in texCommand then
					repeat with ith from 2 to length of commandElements
						set theItem to item ith of commandElements
						if theItem starts with "-interaction=" then
							--set item ith of commandElements to "-interaction=batchmode"
							set item ith of commandElements to "-interaction=nonstopmode"
							exit repeat
						end if
					end repeat
				else
					--set item 1 of commandElements to ((item 1 of commandElements) & space & "-interaction=batchmode")
					set item 1 of commandElements to ((item 1 of commandElements) & space & "-interaction=nonstopmode")
				end if
				set theTexCommand to joinUTextList of StringEngine for commandElements by space
				stopStringEngine() of StringEngine
				
				set pathCommand to "export PATH=/usr/local/bin:$PATH"
				set allCommand to pathCommand & "; " & cdCommand & "; " & theTexCommand & space & "'" & texFileName & "' 2>&1"
				try
					set logContents to do shell script allCommand
				on error errMsg number errNum
					if errNum is 1 then
						-- 1:general tex error
						set logContents to errMsg
						--else if errNum is -1700 then
						-- -1700: unknown, result can not be accept
					else if errNum is 127 then
						-- maybe comannd name or path setting is not correct
						showError(errNum, "texCompile", errMsg) of MessageUtility
						error "Typeset is not executed." number 1250
					else
						error errMsg number errNum
					end if
				end try
			end if
			--log "after Typeset"
			set theDviObj to lookUpDviFile()
			--log "after lookUpDviFile"
			if theDviObj is not missing value then
				setSrcSpecialFlag() of theDviObj
			end if
			--log "end texCompile"
			return theDviObj
		end texCompile
		
		on lookUpDviFile()
			--log "start lookUpDviFile"
			set dviFilePath to getPathWithSuffix(".dvi")
			if isExists(dviFilePath) of UtilityHandlers then
				--log "dviFilePath exists"
				set theDviObj to makeObj(a reference to me) of dviObj
				set dviFileRef of theDviObj to dviFilePath as alias
				return theDviObj
			else
				return missing value
			end if
		end lookUpDviFile
	end script
end makeObj