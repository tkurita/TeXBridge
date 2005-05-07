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
		property myPathConverter : missing value
		--private property
		
		on parseLogFile()
			set logParser to call method "alloc" of class "LogParser"
			set logParser to call method "initWithContentsOfFile:" of logParser with parameter (POSIX path of my logFileRef)
			set parseResult to call method "parseLog" of logParser
			call method "release" of logParser
			log parseResult
			copy PathConverter to myPathConverter
			setHFSoriginPath(my texBasePath) of myPathConverter
			log parseResult
			repeat with theItem in parseResult
				set targetFile to |file| of theItem
				set targetFile to resolveTargetFile(targetFile)
				set errorRecordList to |errorRecordList| of theItem
				repeat with theRecord in errorRecordList
					using terms from application "mi"
						set errorRecord to {file:targetFile, comment:|comment| of theRecord}
						try
							set errorRecord to errorRecord & {paragraph:|paragraph| of theRecord}
						end try
					end using terms from
					set end of hyperlist to errorRecord
				end repeat
			end repeat
			
			set isNoMessages to (hyperlist is {})
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
