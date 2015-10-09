global PathConverter
global LogParser

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

on is_dvi_output()
	return my _logParserCore's isDviOutput() as boolean
end is_dvi_output

on has_output()
    return my _logParserCore's hasOutput() as boolean
end has_output

on is_no_error()
	return my _logParserCore's isNoError() as boolean
end is_no_error

on is_found_outputfile()
    return my _logParserCore's isFoundOutputfile() as boolean
end is_found_outputfile

on labels_changed()
	return my _logParserCore's isLabelsChanged() as boolean
end labels_changed

on output_file()
    return my _logParserCore's outputFile() as text
end output_file

on parseLog(a_log_parser)
	a_log_parser's setBaseURLWithPath_(my _texdoc's no_suffix_posix_path())
	set pre_delim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to space
	set commandName to text item 1 of (my _texdoc's typeset_command())
	set AppleScript's text item delimiters to pre_delim
	a_log_parser's setupJobName_(commandName & space & (my _texdoc's filename()))
	try
		set parseResult to a_log_parser's parseLog()
	on error msg number errno
		error "Error when parsing log. message : " & msg number errno
	end try
	--log parseResult
    set my _logParserCore to a_log_parser
	--log "end parseLog"
end parseLog

on parseLogText()
	--log "start parseLogText"
	tell LogParser
		set a_log_parser to alloc()
	end tell
	set a_log_contents to log_contents()
	--log a_log_contents
	if (a_log_contents starts with "This is") then
		set a_log_parser to a_log_parser's initWithString_(a_log_contents & return)
	else
		set a_log_parser to a_log_parser's initWithContentsOfFile_encodingName_(logfile()'s posix_path(), my _texdoc's text_encoding())
	end if
	
	set err_msg to a_log_parser's errorMessage() as text
	if err_msg is not "" then
		error err_msg number 1245
	end if
	parseLog(a_log_parser)
	--log "end parseLogText"
end parseLogText

on parse_logfile()
	set logfile_path to logfile()'s posix_path()
	tell LogParser
		set a_log_parser to alloc()'s initWithContentsOfFile_encodingName_(logfile_path, my _texdoc's text_encoding())
	end tell
	set err_msg to a_log_parser's errorMessage() as text
	if err_msg is not "" then
		error err_msg number 1245
	end if
	parseLog(a_log_parser)
end parse_logfile

on texdoc()
	return my _texdoc
end texdoc

on make_with(a_texdoc)
	script LogFileParser
		property _texdoc : a_texdoc
        property _hasOutput : false
		property _isDviOutput : true
		property _isNoError : true
		property _isLabelsChanged : false
        property _logParserCore : missing value
	end script
	
	return LogFileParser
end make_with
