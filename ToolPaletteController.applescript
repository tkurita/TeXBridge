property targetWindow : missing value
property WindowController : missing value

on initilize()
	set WindowController to call method "alloc" of class "ToolPaletteController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "ToolPalette"
	set targetWindow to call method "window" of WindowController
	call method "retain" of targetWindow
end initilize

on open_window()
	if WindowController is missing value then
		initilize()
	end if
	call method "showWindow:" of WindowController
end open_window

on showStatusMessage(theMessage)
	if (WindowController is not missing value) then
		if (call method "isCollapsed" of WindowController) is 0 then
			set contents of text field "StatusMessage" of targetWindow to theMessage
			update targetWindow
		end if
	end if
end showStatusMessage

on isOpened()
	if WindowController is missing value then
		return false
	end if
	set theResult to call method "isOpened" of WindowController
	return (theResult is 1)
end isOpened
