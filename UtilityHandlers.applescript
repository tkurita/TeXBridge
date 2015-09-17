global XText
global appController

property yenmark : missing value
property backslash : missing value

on clean_yenmark(a_xtext)
	if yenmark is missing value then
		tell appController
			set yenmark to factoryDefaultForKey_("yenmark") as text
			set backslash to factoryDefaultForKey_("backslash") as text
		end tell
	end if
	if class of a_xtext is script then
		set a_result to a_xtext's replace(yenmark, backslash)
	else
		set a_result to XText's make_with(a_xtext)'s replace(yenmark, backslash)'s as_unicode()
	end if
end clean_yenmark

on xlocalized_string(a_keyword, insert_texts)
	set a_text to localized string a_keyword
	--log a_keyword & ":" & a_text
	return XText's make_with(a_text)'s format_with(insert_texts)
end xlocalized_string

on localized_string(a_keyword, insert_texts)
	return xlocalized_string(a_keyword, insert_texts)'s as_unicode()
end localized_string

on is_running(app_name)
	tell application "System Events"
		return exists application process app_name
	end tell
end is_running

on show_error(errno, place, msg)
	activate
	set a_msg to localized_string("error_msg", {errno, place, msg})
	display alert a_msg
end show_error

on show_message(a_msg)
	activate
	display alert a_msg
end show_message

on show_localized_message(a_msg)
    activate
    display alert (localized string a_msg)
end show_localized_message