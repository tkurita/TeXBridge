property XHandler : module
property _ : boot (module loader of application (get "TeXToolsLib")) for me

on clicked theObject
	set a_name to name of theObject
	if a_name is "setting" then
		script x_handler
			on do(an_object)
				an_object's show_setting_window()
			end do
		end script
		open {commandClass:"action", commandScript:x_handler}
	else
		set x_handler to XHandler's make_with(a_name, 0)
		open {commandClass:"compile", commandScript:x_handler}
	end if
	
end clicked
