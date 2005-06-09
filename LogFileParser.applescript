global yenmark
global PathConverter

on makeObj(theTexDocObj)
	script LogFileParser
		property parent : theTexDocObj
		--property logFileRef : missing value
		property isDviOutput : true
		property hyperlist : {}
		property retryCompile : false
		property isNoError : true
		property isNoMessages : false
		property isLabelsChanged : false
		
		property myPathConverter : missing value
		--private property
		
		on buildHyperList(parseResult)
			--log "start buildHyperList"
			copy PathConverter to myPathConverter
			setHFSoriginPath(my texBasePath) of myPathConverter
			--log parseResult
			repeat with theItem in parseResult
				set targetFile to |file| of theItem
				set errorRecordList to |errorRecordList| of theItem
				
				if targetFile is not "" then
					set targetFile to resolveTargetFile(targetFile)
					
					repeat with theRecord in errorRecordList
						using terms from application "mi"
							set errorRecord to {file:targetFile, comment:|comment| of theRecord}
							try
								set errorRecord to errorRecord & {paragraph:|paragraph| of theRecord}
							end try
						end using terms from
						set end of hyperlist to errorRecord
					end repeat
				else
					repeat with theRecord in errorRecordList
						using terms from application "mi"
							set errorRecord to {comment:|comment| of theRecord}
						end using terms from
						set end of hyperlist to errorRecord
					end repeat
				end if
			end repeat
			
			set isNoMessages to (hyperlist is {})
		end buildHyperList
		
		on boolValue(theValue)
			return theValue is 1
		end boolValue
		
		on parseLog(logParser)
			set parseResult to call method "parseLog" of logParser
			--log parseResult
			set isDviOutput to boolValue(call method "isDviOutput" of logParser)
			set isLabelsChanged to boolValue(call method "isLabelsChanged" of logParser)
			call method "release" of logParser
			buildHyperList(parseResult)
		end parseLog
		
		on parseLogText()
			--log "start parseLogText"
			if (count paragraph of my logContents) > 1 then
				set logParser to call method "alloc" of class "LogParser"
				set logParser to call method "initWithString:" of logParser with parameter my logContents
				parseLog(logParser)
			else
				parseLogFile()
			end if
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
