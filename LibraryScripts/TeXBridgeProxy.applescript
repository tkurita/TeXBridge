property XText : "@module"
property _targetPlist : missing value
property _defaults_domain : "TeXBridge"

on localized_string(a_key, insert_texts)
	set a_text to localized string a_key in bundle ((my _texbridge) as POSIX file)
	tell XText
		store_delimiters()
		set a_text to formated_text given template:a_text, args:insert_texts
		restore_delimiters()
	end tell
	return a_text
end localized_string

on userdefaults_for(a_name, a_value)
	try
		set a_result to do shell script "defaults read " & _defaults_domain & space & quoted form of a_name
	on error
		set a_result to a_value
	end try
	return a_result
end userdefaults_for

on set_userdefaults_for(a_name, a_value)
	do shell script "defaults write " & _defaults_domain & space & quoted form of a_name & space & quoted form of a_value
end set_userdefaults_for

on quickset_userdefaults_for(a_name, a_value)
	set_userdefaults_for(a_name, a_value)
end quickset_userdefaults_for


on activate_process(an_identifier)
	using terms from application "TeXBridge"
		tell application (my _texbridge)
			ignoring application responses
				activate process an_identifier
			end ignoring
		end tell
	end using terms from
end activate_process


on path_to_texbridge()
	if application id "net.script-factory.TeXBridge" is running then
		--do shell script "logger -p user.warning  -t TeXBridge -s 'TeXBridge is runnning'"
		return POSIX path of (path to application "TeXBridge")
	end if
	--do shell script "logger -p user.warning  -t TeXBridge -s 'TeXBridge is not runnning'"
	set ver to version of current application
	considering numeric strings
		set mi_third to (ver ≥ "3.0")
	end considering
	if mi_third then
		set path_list to {(path to application support from user domain)'s POSIX path & "mi3/mode/TEX/TeXBridge.app"}
	else
		set path_list to {(path to application support from user domain)'s POSIX path & "mi/mode/TEX/TeXBridge.app", ¬
			(path to preferences from user domain)'s POSIX path & "mi/mode/TEX/TeXBridge.app"}
	end if
	repeat with a_path in path_list
		--log a_path
		try
			(a_path as POSIX file) as alias
			return a_path
		end try
	end repeat
	error "Can't find TeXBridge." number 1325
	return missing value
end path_to_texbridge

on plist_value(a_name)
	tell application "System Events"
		return value of property list item a_name of my _targetPlist
	end tell
end plist_value

on resolve_support_plist()
	--log "start resolve_support_plist"
	set plist_name to "ToolSupport.plist"
	set plist_path to path to resource plist_name in bundle ((my _texbridge) as POSIX file)
	tell application "System Events"
		set my _targetPlist to property list file (POSIX path of plist_path)
	end tell
	--log "end reslove_support_plist"
end resolve_support_plist

on do_command(arg)
	try
		tell application (my _texbridge)
			launch
			using terms from application "TeXBridge"
				ignoring application responses
					perform task with script arg
				end ignoring
			end using terms from
		end tell
	on error msg
		display alert msg
		return false
	end try
	return true
end do_command

on app_path()
	return my _texbridge
end app_path

on make
	set a_path to path_to_texbridge()
	if a_path is missing value then return missing value
	set a_class to me
	script TeXBridgeProxy
		property parent : a_class
		property _texbridge : a_path
		property _targetPlist : missing value
	end script
	return TeXBridgeProxy
end make

on debug()
	set TeXBridge to make me
	TeXBridge's resolve_support_plist()
end debug

on run
	debug()
end run