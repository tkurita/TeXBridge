global ScriptImporter
global TerminalSettingObj
global ReplaceInput
global appController

(* shared variable *)

property _window_controller : missing value
property _window : missing value

property isLoadedTerminalSetting : false
property isLoadedPreviewSetting : false
property isLoadedReplaceInputSetting : false

on RevertToDefault()
	--log "start RevertToDefault"
	set currentTab to current tab view item of tab view "SettingTabs" of my _window
	set theName to name of currentTab
	if theName is "TerminalSetting" then
		revertToFactorySetting() of TerminalSettingObj
		set isLoadedTerminalSetting to false
	else if theName is "TeXCommands" then
		call method "revertToFactoryDefaultForKey:" of appController with parameter "typesetCommand"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "dvipdfCommand"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "dvipsCommand"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "ebbCommand"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "bibtexCommand"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "mendexCommand"
	else if theName is "PreviewSetting" then
		call method "revertToFactoryDefaultForKey:" of appController with parameter "dviViewCommand"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "DVIPreviewMode"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "PDFPreviewMode"
	else if theName is "TheOtherSetting" then
		call method "revertToFactoryDefaultForKey:" of appController with parameter "AutoMultiTypeset"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "ShowToolPaletteWhenLaunched"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "ShowRefPaletteWhenLaunched"
		call method "revertToFactoryDefaultForKey:" of appController with parameter "ToolPaletteApplicationsFloatingOn"
	end if
	
	selectedTab(currentTab)
	--log "end RevertToDefault"
end RevertToDefault

on loadTerminalSetting(theView)
	if not isLoadedTerminalSetting then
		setSettingToWindow(theView) of TerminalSettingObj
		set isLoadedTerminalSetting to true
	end if
end loadTerminalSetting

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

on loadReplaceInputSetting(theView)
	if not isLoadedReplaceInputSetting then
		if ReplaceInput is missing value then
			--log "load ReplaceInput"
			set ReplaceInput to ScriptImporter's do("ReplaceInput")
		end if
		setSettingToWindow(theView) of ReplaceInput
		set isLoadedReplaceInputSetting to true
	end if
end loadReplaceInputSetting

on selectedTab(tabViewItem)
	set theName to name of tabViewItem
	if theName is "TerminalSetting" then
		loadTerminalSetting(tabViewItem)
	else if theName is "PreviewSetting" then
		loadPreviewSetting(tabViewItem)
	else if theName is "ReplaceInputSetting" then
		loadReplaceInputSetting(tabViewItem)
	end if
end selectedTab

on initilize()
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
	set mxdviEditorField to text field "MxdviEditorSetting" of box "MxdviEditorBox" of tab view item "PreviewSetting" of tab view "SettingTabs" of my _window
	if theSetting is missing value then
		set theSetting to contents of contents of mxdviEditorField
	else
		set contents of contents of mxdviEditorField to theSetting
	end if
	if theSetting is not "" then
		set a_command to "defaults write Mxdvi MxdviEditor " & (quoted form of theSetting)
		--log a_command
		do shell script a_command
	end if
	--log "end saveMxdviEditor"
end saveMxdviEditor

on displayAlert(a_msg)
	display alert a_msg attached to my _window as warning
end displayAlert
