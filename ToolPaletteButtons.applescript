property XHandler : load("XHandler") of application (get "TeXToolsLib")

on clicked theObject
	set a_name to name of theObject
	if a_name is "setting" then
		script x_handler
			on do(an_object, arg)
				an_object's SettingWindowController's open_window()
			end do
		end script
		open {commandClass:"action", commandScript:x_handler}
	else
		set x_handler to XHandler's make_with(a_name)
		open {commandClass:"compile", commandScript:x_handler}
	end if
	
end clicked
