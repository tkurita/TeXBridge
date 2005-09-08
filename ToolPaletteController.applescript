property targetWindow : missing value
property WindowController : missing value

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
