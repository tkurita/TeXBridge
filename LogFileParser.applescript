global PathConverter

on makeObj(theTexDocObj)
	script LogFileParser
		property parent : theTexDocObj
		property _isDviOutput : true
		property _isNoError : true
		property hyperlist : {}
		property retryCompile : false
		property isNoMessages : false
		property isLabelsChanged : false
		property myPathConverter : missing value
		
		on boolValue(theValue)
			return theValue is 1
		end boolValue
		
		on isDviOutput()
			return _isDviOutput
		end isDviOutput
		
		on isNoError()
			return _isNoError
		end isNoError
		
		on parseLog(logParser)
			call method "setBaseURLWithPath:" of logParser with parameter (POSIX path of my texBasePath)
			set preDelim to AppleScript's text item delimiters
			set AppleScript's text item delimiters to space
			set commandName to text item 1 of (my texCommand)
			set AppleScript's text item delimiters to preDelim
			call method "setJobName:" of logParser with parameter (commandName & space & my texFileName)
			set parseResult to call method "parseLog" of logParser
			--log parseResult
			set _isDviOutput to boolValue(call method "isDviOutput" of logParser)
			set _isNoError to boolValue(call method "isNoError" of logParser)
			set isLabelsChanged to boolValue(call method "isLabelsChanged" of logParser)
			--buildHyperList(parseResult)
			call method "release" of logParser
			--log "end parseLog"
		end parseLog
		
		on parseLogText()
			--log "start parseLogText"
			set logParser to call method "alloc" of class "LogParser"
			if (my logContents starts with "This is") then
				set logParser to call method "initWithString:" of logParser with parameter ((my logContents) & return)
			else
				set logParser to call method "initWithContentsOfFile:" of logParser with parameter (POSIX path of my logFileRef)
			end if
			parseLog(logParser)
			--log "end parseLogText"
		end parseLogText
		
		on parseLogFile()
			set logParser to call method "alloc" of class "LogParser"
			set logParser to call method "initWithContentsOfFile:" of logParser with parameter (POSIX path of my logFileRef)
			parseLog(logParser)
		end parseLogFile
		
		on resolveTargetFile(theTargetFile)
			if (theTargetFile starts with "./") or (theTargetFile starts with "../") then
				set theTargetFile to getHFSfromPOSIXpath of myPathConverter for theTargetFile
				set theTargetFile to getAbsolutePath of myPathConverter for theTargetFile
				set theTargetFile to theTargetFile as alias
			else
				set theTargetFile to (POSIX file theTargetFile) as alias
			end if
			return theTargetFile
		end resolveTargetFile
	end script
	
	return LogFileParser
end makeObj
