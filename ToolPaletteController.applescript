property _window : missing value
property _window_controller : missing value

on window_controller()
	return my _window_controller
end window_controller

on initilize()
	set my _window_controller to call method "alloc" of class "ToolPaletteController"
	set my _window_controller to call method "initWithWindowNibName:" of my _window_controller with parameter "ToolPalette"
	set my _window to call method "window" of my _window_controller
	call method "retain" of my _window
end initilize

on open_window()
	if my _window_controller is missing value then
		initilize()
	end if
	call method "showWindow:" of my _window_controller
end open_window

on show_status_message(a_msg)
	if (my _window_controller is not missing value) then
		if (call method "isCollapsed" of my _window_controller) is 0 then
			set contents of text field "StatusMessage" of my _window to a_msg
			update my _window
		end if
	end if
end show_status_message

on is_opend()
	if my _window_controller is missing value then
		return false
	end if
	set a_result to call method "is_opend" of my _window_controller
	return (a_result is 1)
end is_opend
