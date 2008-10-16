global TerminalSettings
global appController

(* shared variable *)

property _window_controller : missing value
property _window : missing value

property isLoadedPreviewSetting : false

on window_controller()
	if my _window_controller is missing value then
		initilize()
	end if
	return my _window_controller
end window_controller

on loadPreviewSetting(theView)
	if not isLoadedPreviewSetting then
		try
			set currentMxdviEditor to do shell script "defaults read Mxdvi MxdviEditor"
		on error
			-- MxdviEditor is not defined
			set currentMxdviEditor to ""
		end try
		tell theView
			set contents of text field "MxdviEditorSetting" of box "MxdviEditorBox" to currentMxdviEditor
		end tell
		
		set isLoadedPreviewSetting to true
	end if
end loadPreviewSetting




on updated_selected_tab_view_item()
	set a_tab to current tab view item of tab view "SettingTabs" of my _window
	selectedTab(a_tab)
end updated_selected_tab_view_item

on initilize()
	--log "start initialize"
	set my _window_controller to call method "alloc" of class "SettingWindowController"
	set my _window_controller to call method "initWithWindowNibName:" of my _window_controller with parameter "Setting"
	set my _window to call method "window" of my _window_controller
	selectedTab(current tab view item of tab view "SettingTabs" of my _window)
end initilize

on open_window()
	if my _window_controller is missing value then
		initilize()
	end if
	activate
	call method "showWindow:" of my _window_controller
end open_window

on display_alert(a_msg)
	display alert a_msg attached to my _window as warning
end display_alert
