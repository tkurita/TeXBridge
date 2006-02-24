property targetWindow : missing value
property WindowController : missing value

on initilize()
	set WindowController to call method "alloc" of class "ToolPaletteController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "ToolPalette"
	set targetWindow to call method "window" of WindowController
	call method "retain" of targetWindow
end initilize

on openWindow()
	if WindowController is missing value then
		initilize()
	end if
	call method "showWindow:" of WindowController
end openWindow

on showStatusMessage(theMessage)
	if (WindowController is not missing value) then
		if (call method "isCollapsed" of WindowController) is 0 then
			set contents of text field "StatusMessage" of targetWindow to theMessage
			update targetWindow
		end if
	end if
end showStatusMessage