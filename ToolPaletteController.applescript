property targetWindow : missing value
property WindowController : missing value

on stopTimer()
	if WindowController is not missing value then
		call method "temporaryStopDisplayToggleTimer" of WindowController
	end if
end stopTimer

on restartTimer()
	if WindowController is not missing value then
		call method "restartStopDisplayToggleTimer" of WindowController
	end if
end restartTimer

on initilize()
	set WindowController to call method "alloc" of class "ToolPaletteController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "ToolPalette"
	set targetWindow to call method "window" of WindowController
end initilize

on openWindow()
	--activate
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