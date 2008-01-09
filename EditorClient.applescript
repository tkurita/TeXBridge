global StringEngine

property parent : load("miClient") of application (get "TeXToolsLib")

(*
on save_with_asking()
	set do_you_save_msg to localized string "doYouSave"
	
	tell application "mi"
		set a_name to name of document 1
	end tell
	
	tell StringEngine
		store_delimiters()
		set doc_modified_msg to formated_text given template:(localized string "docIsModified"), args:{a_name}
		restore_delimiters()
	end tell
	
	tell application "mi"
		try
			set a_result to display dialog (doc_modified_msg & return & do_you_save_msg)
		on error number -128
			return false
		end try
		save document 1
		return true
	end tell
end save_with_asking
*)

on show_message_asking(msg)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	tell application "mi"
		try
			display dialog msg
		on error
			return false
		end try
	end tell
	return true
end show_message_asking

on show_message_buttons(msg, button_list, default_button)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	tell application "mi"
		try
			set a_result to display dialog msg buttons button_list default button default_button
		on error
			set a_result to {button returned:missing value}
		end try
	end tell
	return a_result
end show_message_buttons

on show_message(msg)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	tell application "mi"
		display alert msg
	end tell
end show_message

(*
on open_with_activating(a_file)
	open_file(a_file)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
end open_with_activating
*)