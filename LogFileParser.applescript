global PathConverter

on boolValue(theValue)
	return theValue is 1
end boolValue

(*== accessors *)
on logfile()
	return my _texdoc's logfile()
end logfile

on log_contents()
	return my _texdoc's log_contents()
end log_contents

on isDviOutput()
	return my _isDviOutput
end isDviOutput

on isNoError()
	return my _isNoError
end isNoError

on labels_changed()
	return my _isLabelsChanged
end labels_changed

on parseLog(logParser)
	call method "setBaseURLWithPath:" of logParser with parameter (my _texdoc's no_suffix_posix_path())
	set preDelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to space
	set commandName to text item 1 of (my _texdoc's typeset_command())
	set AppleScript's text item delimiters to preDelim
	call method "setJobName:" of logParser with parameter (commandName & space & (my _texdoc's filename()))
	try
		set parseResult to call method "parseLog" of logParser
	on error msg number errno
		error "Error when parsing log. message : " & msg number errno
	end try
	--log parseResult
	set my _isDviOutput to boolValue(call method "isDviOutput" of logParser)
	set my _isNoError to boolValue(call method "isNoError" of logParser)
	set my _isLabelsChanged to boolValue(call method "isLabelsChanged" of logParser)
	call method "release" of logParser
	--log "end parseLog"
end parseLog

on parseLogText()
	--log "start parseLogText"
	set logParser to call method "alloc" of class "LogParser"
	set a_log_contents to log_contents()
	if (a_log_contents starts with "This is") then
		set logParser to call method "initWithString:" of logParser with parameter (a_log_contents & return)
	else
		set logParser to call method "initWithContentsOfFile:encodingName:" of logParser with parameters {(logfile()'s posix_path()), my _texdoc's text_encoding()}
	end if
	parseLog(logParser)
	--log "end parseLogText"
end parseLogText

on parse_logfile()
	set logParser to call method "alloc" of class "LogParser"
	set logParser to call method "initWithContentsOfFile:encodingName:" of logParser with parameters {(logfile()'s posix_path()), my _texdoc's text_encoding()}
	parseLog(logParser)
end parse_logfile

on resolveTargetFile(theTargetFile)
	if (theTargetFile starts with "./") or (theTargetFile starts with "../") then
		set theTargetFile to hfs_from_posix(theTargetFile) of my _pathConverter
		set theTargetFile to absolute_path of (my _pathConverter) for theTargetFile
		set theTargetFile to theTargetFile as alias
	else
		set theTargetFile to (POSIX file theTargetFile) as alias
	end if
	return theTargetFile
end resolveTargetFile

on make_with(a_texdoc)
	script LogFileParser
		property _texdoc : a_texdoc
		property _isDviOutput : true
		property _isNoError : true
		--property _retryCompile : false -- obsoleted ?
		--property _isNoMessages : false
		property _isLabelsChanged : false
		property _pathConverter : missing value
	end script
	
	return LogFileParser
end make_with
