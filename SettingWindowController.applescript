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


on selectedTab(tabViewItem)
	set a_name to name of tabViewItem
	if a_name is "PreviewSettings" then
		loadPreviewSetting(tabViewItem)
	end if
end selectedTab

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

on setmiclient()
	--log "start setmiclient"
	tell main bundle
		set miclientPath to resource path & "/miclient"
		--set miclientPath to path for resource "miclient"
	end tell
	saveMxdviEditor(miclientPath & " -b %l %f")
end setmiclient

on saveMxdviEditor(theSetting)
	--log "start saveMxdviEditor"
	set mxdviEditorField to text field "MxdviEditorSetting" of box "MxdviEditorBox" of tab view item "PreviewSettings" of tab view "SettingTabs" of my _window
	if theSetting is missing value then
		set theSetting to contents of contents of mxdviEditorField
	else
		set contents of contents of mxdviEditorField to theSetting
	end if
	if theSetting is not "" then
		set a_command to "defaults write Mxdvi MxdviEditor " & (quoted form of theSetting)
		do shell script a_command
	end if
	--log "end saveMxdviEditor"
end saveMxdviEditor

on display_alert(a_msg)
	display alert a_msg attached to my _window as warning
end display_alert
