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

on showMessageWithAsk(a_msg)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	tell application "mi"
		try
			display dialog a_msg
		on error
			return false
		end try
	end tell
	return true
end showMessageWithAsk

on showMessageWithButtons(a_msg, buttonList, defaultButton)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	tell application "mi"
		try
			set theResult to display dialog a_msg buttons buttonList default button defaultButton
		on error
			set theResult to {button returned:missing value}
		end try
	end tell
	return theResult
end showMessageWithButtons

on show_message(msg)
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	tell application "mi"
		display alert msg
	end tell
end show_message
