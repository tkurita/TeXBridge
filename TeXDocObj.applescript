global PathConverter
global PathAnalyzer
global StringEngine
global UtilityHandlers
global TerminalCommander
global MessageUtility
global DviObj
global ToolPaletteController

property name : "TeXDocObj"
property logSuffix : ".log"
property texSuffixList : {".tex", ".dtx"}

global comDelim

(*== Private Methods *)
on remove_suffix(a_text)
	repeat with ith from 1 to length of my texSuffixList
		set a_suffix to item ith of my texSuffixList
		if a_text ends with a_suffix then
			set suffix_len to length of a_suffix
			set a_text to text 1 thru (-1 * (suffix_len + 1)) of a_text
			exit repeat
		end if
	end repeat
	return a_text
end remove_suffix

(*== Instance methods *)
on path_for_suffix(an_extension)
	if my texBasePath is missing value then
		set my texBasePath to my texFileRef as Unicode text
		set my texBasePath to remove_suffix(my texBasePath)
	end if
	return my texBasePath & an_extension
end path_for_suffix

on open_outfile(an_extension)
	set file_path to path_for_suffix(an_extension)
	try
		tell application "Finder"
			open (file_path as alias)
		end tell
	on error msg number errno
		activate
		display alert msg message "Error Number : " & errno
	end try
end open_outfile

on lookup_dvi()
	--log "start lookup_dvi"
	set dvi_path to path_for_suffix(".dvi")
	if isExists(dvi_path) of UtilityHandlers then
		--log "dviFilePath exists"
		set a_dvi_obj to makeObj(me) of DviObj
		set dviFileRef of a_dvi_obj to dvi_path as alias
		set_file_type() of a_dvi_obj
		return a_dvi_obj
	else
		return missing value
	end if
end lookup_dvi

(*== Constructors *)
on makeObjFromDVIFile(dvi_file_ref)
	--log "start makeObjFromDVIFile"
	local basepath
	set dvi_path to dvi_file_ref as Unicode text
	if dvi_path ends with ".dvi" then
		set basepath to text 1 thru -5 of dvi_path
	else
		set basepath to dvi_path
	end if
	set tex_path to basepath & ".tex"
	
	if isExists(POSIX file tex_path) of UtilityHandlers then
		set tex_doc_obj to makeObj(POSIX file tex_path)
		getHeaderCommandFromFile() of tex_doc_obj
	else
		set tex_doc_obj to makeObj(POSIX file basepath)
	end if
	
	return tex_doc_obj
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
		
		(*
		on getLogContents()
			return logContetns of logContainer
		end getLogContents
		*)
		
		on resolveParentFile(a_paragraph)
			--log "start resolveParentFile"
			set parentFile to StringEngine's strip(text 13 thru -2 of a_paragraph)
			--log parentFile
			if parentFile starts with ":" then
				set_base_path(targetFileRef) of PathConverter
				set theTexFile to absolute_path of PathConverter for parentFile
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
		
		on getHeaderCommand(a_paragraph)
			ignoring case
				if a_paragraph starts with "%ParentFile" then
					set theParentFile to resolveParentFile(a_paragraph)
					setTexFileRef(theParentFile)
				else if a_paragraph starts with "%Typeset-Command" then
					set my texCommand to StringEngine's strip(text 18 thru -1 of a_paragraph)
				else if a_paragraph starts with "%DviToPdf-Command" then
					set my dvipdfCommand to StringEngine's strip(text 19 thru -1 of a_paragraph)
				else if a_paragraph starts with "%DviToPs-Command" then
					set my dvipsCommand to StringEngine's strip(text 18 thru -1 of a_paragraph)
				end if
			end ignoring
		end getHeaderCommand
		
		on getHeaderCommandFromFile()
			--log "start getHearderCommandFromFile"
			set lineFeed to ASCII character 10
			set inputFile to open for access texFileRef
			set a_paragraph to read inputFile before lineFeed
			repeat while (a_paragraph starts with "%")
				getHeaderCommand(a_paragraph)
				try
					set a_paragraph to read inputFile before lineFeed
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
			if my texBaseName is missing value then
				set my texBaseName to my texFileName as Unicode text
				set my texBaseName to remove_suffix(my texBaseName)
			end if
			return my texBaseName
		end getBaseName
		
		on buildCommand(theCommand, theSuffix)
			-- replace %s in theCommand with texBaseName. if %s is not in theCommand, texBaseName+theSuffix is added end of theCommand
			if "%s" is in theCommand then
				set theBaseName to getBaseName()
				store_delimiters() of StringEngine
				set theCommand to replace of StringEngine for theCommand from "%s" by theBaseName
				restore_delimiters() of StringEngine
				return theCommand
			else
				set targetFileName to getNameWithSuffix(theSuffix)
				return (theCommand & space & "'" & targetFileName & "'")
			end if
		end buildCommand
		
		on checkLogFileStatus()
			set textALogfile to localized string "aLogfile"
			set textHasBeenOpend to localized string "hasBeenOpend"
			set textShouldClose to localized string "shouldClose"
			set textCancel to localized string "Cancel"
			set textClose to localized string "Close"
			
			set theLogFile to path_for_suffix(logSuffix)
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
		
		on texCompile()
			--log "start texCompile"
			set beforeCompileTime to current date
			set cdCommand to "cd " & (quoted form of POSIX path of (workingDirectory))
			
			if texCommand is missing value then
				set texCommand to contents of default entry "typesetCommand" of user defaults
			end if
			
			if compileInTerminal then
				set allCommand to cdCommand & comDelim & texCommand & space & "'" & texFileName & "'"
				--doCommands of TerminalCommander for allCommand with activation
				sendCommands of TerminalCommander for allCommand
				copy TerminalCommander to currentTerminal
				delay 1
				waitEndOfCommand(300) of currentTerminal
			else
				store_delimiters() of StringEngine
				set commandElements to split of StringEngine for texCommand by space
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
				set theTexCommand to join of StringEngine for commandElements by space
				restore_delimiters() of StringEngine
				
				--set pathCommand to "export PATH=/usr/local/bin:$PATH"
				--set allCommand to pathCommand & "; " & cdCommand & "; " & theTexCommand & space & "'" & texFileName & "' 2>&1"
				set shell_path to getShellPath() of TerminalCommander
				set allCommand to cdCommand & ";exec " & shell_path & " -lc " & quote & theTexCommand & space & (quoted form of texFileName) & " 2>&1" & quote
				try
					set logContents to do shell script allCommand
				on error errMsg number errNum
					if errNum is 1 then
						-- 1:general tex error
						set logContents to errMsg
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
			set theDviObj to lookup_dvi()
			--log "after lookup_dvi"
			if theDviObj is not missing value then
				setSrcSpecialFlag() of theDviObj
			end if
			--log "end texCompile"
			return theDviObj
		end texCompile
		
		
	end script
end makeObj