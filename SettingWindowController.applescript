global ScriptImporter
global TerminalSettingObj
global ReplaceInput
global appController

(* shared variable *)

property WindowController : missing value
property targetWindow : missing value

property isLoadedTerminalSetting : false
property isLoadedPreviewSetting : false
property isLoadedReplaceInputSetting : false

on RevertToDefault()
	--log "start RevertToDefault"
	set currentTab to current tab view item of tab view "SettingTabs" of my targetWindow
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
	set WindowController to call method "alloc" of class "SettingWindowController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "Setting"
	set targetWindow to call method "window" of WindowController
	selectedTab(current tab view item of tab view "SettingTabs" of my targetWindow)
end initilize

on open_window()
	if WindowController is missing value then
		initilize()
	end if
	activate
	call method "showWindow:" of WindowController
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
	set mxdviEditorField to text field "MxdviEditorSetting" of box "MxdviEditorBox" of tab view item "PreviewSetting" of tab view "SettingTabs" of my targetWindow
	if theSetting is missing value then
		set theSetting to contents of contents of mxdviEditorField
	else
		set contents of contents of mxdviEditorField to theSetting
	end if
	if theSetting is not "" then
		set theCommand to "defaults write Mxdvi MxdviEditor " & (quoted form of theSetting)
		--log theCommand
		do shell script theCommand
	end if
	--log "end saveMxdviEditor"
end saveMxdviEditor

on displayAlert(theMessage)
	display alert theMessage attached to targetWindow as warning
end displayAlert
