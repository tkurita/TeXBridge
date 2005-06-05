global WindowController

on makeObj(theWindow)
	set theWindowController to makeObj(theWindow) of WindowController
	
	script SettingWindowController
		(* shared script object *)
		global TerminalSettingObj
		global TeXCompileObj
		global PDFObj
		global TexDocObj
		global dviObj
		global ReplaceInputObj
		global UtilityHandlers
		global DefaultsManager
		
		(* shared variable *)
		global lifeTime
		global showToolPaletteWhenLaunched
		global showRefPaletteWhenLaunched
		
		property parent : theWindowController
		property theOtherSettingTab : missing value
		
		property isLoadedTerminalSetting : false
		property isLoadedCommandSetting : false
		property isLoadedPreviewSetting : false
		property isLoadedOtherSetting : false
		property isLoadedReplaceInputSetting : false
		
		on showHelp()
			set infoDict to call method "infoDictionary" of main bundle
			set bookName to |CFBundleHelpBookName| of infoDict
			set theAnchor to name of current tab view item of tab view "SettingTabs" of my targetWindow
			tell application "Help Viewer"
				activate
				lookup anchor theAnchor in book bookName
			end tell
		end showHelp
		
		on RevertToDefault()
			--log "start RevertToDefault"
			revertToFactorySetting() of TeXCompileObj
			revertToFactorySetting() of TexDocObj
			revertToFactorySetting() of dviObj
			revertToFactorySetting() of PDFObj
			revertToFactorySetting() of TerminalSettingObj
			revertToFactorySetting()
			
			set isLoadedTerminalSetting to false
			set isLoadedCommandSetting to false
			set isLoadedPreviewSetting to false
			set isLoadedOtherSetting to false
			
			selectedTab(current tab view item of tab view "SettingTabs" of my targetWindow)
		end RevertToDefault
		
		on loadTerminalSetting(theView)
			if not isLoadedTerminalSetting then
				setSettingToWindow(theView) of TerminalSettingObj
				set isLoadedTerminalSetting to true
			end if
		end loadTerminalSetting
		
		on loadCommandSetting(theView)
			if not isLoadedCommandSetting then
				tell theView
					set contents of text field "typesetCommand" to defaultTexCommand of TexDocObj
					set contents of text field "dvipdfCommand" to defaultDVIPDFCommand of dviObj
				end tell
				setSettingToWindow(theView) of TeXCompileObj
				set isLoadedCommandSetting to true
			end if
		end loadCommandSetting
		
		on loadPreviewSetting(theView)
			if not isLoadedPreviewSetting then
				try
					set currentMxdviEditor to do shell script "defaults read Mxdvi MxdviEditor"
				on error
					-- MxdviEditor is not defined
					set currentMxdviEditor to ""
				end try
				tell theView
					set current row of matrix "PDFPreview" to PDFPreviewIndex of PDFObj
					set contents of text field "dviViewCommand" to dviViewCommand of dviObj
					set current row of matrix "PreviewerMode" to DVIPreviewMode of dviObj
					set contents of text field "MxdviEditorSetting" to currentMxdviEditor
				end tell
				
				set isLoadedPreviewSetting to true
			end if
		end loadPreviewSetting
		
		on loadOtherSetting(theView)
			--log "start loadOtherSetting"
			if not isLoadedOtherSetting then
				set contents of text field "LifeTime" of theView to (lifeTime div 60) as integer
				
				if showToolPaletteWhenLaunched then
					set state of button "ShowToolPaletteWhenLaunched" of theView to 1
				else
					set state of button "ShowToolPaletteWhenLaunched" of theView to 0
				end if
				
				if showRefPaletteWhenLaunched then
					set state of button "ShowRefPaletteWhenLaunched" of theView to 1
				else
					set state of button "ShowRefPaletteWhenLaunched" of theView to 0
				end if
				
				if autoMultiTypeset of TeXCompileObj then
					set state of button "AutoMultiTypeset" of theView to 1
				else
					set state of button "AutoMultiTypeset" of theView to 0
				end if
				
				set isLoadedOtherSetting to true
			end if
			--log "end loadOtherSetting"
		end loadOtherSetting
		
		on loadReplaceInputSetting(theView)
			if not isLoadedReplaceInputSetting then
				if ReplaceInputObj is missing value then
					--log "load ReplaceInputObj"
					set ReplaceInputObj to importScript("ReplaceInputObj") of UtilityHandlers
				end if
				setSettingToWindow(theView) of ReplaceInputObj
				set isLoadedReplaceInputSetting to true
			end if
		end loadReplaceInputSetting
		
		on selectedTab(tabViewItem)
			set theName to name of tabViewItem
			if theName is "TerminalSetting" then
				loadTerminalSetting(tabViewItem)
			else if theName is "TeXCommands" then
				loadCommandSetting(tabViewItem)
			else if theName is "PreviewSetting" then
				loadPreviewSetting(tabViewItem)
			else if theName is "ReplaceInputSetting" then
				loadReplaceInputSetting(tabViewItem)
			else if theName is "TheOtherSetting" then
				loadOtherSetting(tabViewItem)
			end if
		end selectedTab
		
		on endEditing(theObject)
			set theName to name of theObject
			if theName is "LifeTime " then
				set theLifeTime to (contents of theObject) as string
				if theLifeTime is not "" then
					set lifeTime to (theLifeTime as integer) * 60
				end if
				
				set contents of default entry "LifeTime" to lifeTime of user defaults
			end if
		end endEditing
		
		on controlClicked(theObject)
			set theName to name of theObject
			if theName is "ShowToolPaletteWhenLaunched" then
				set showToolPaletteWhenLaunched to (state of theObject is 1)
				tell user defaults
					set contents of default entry "ShowToolPaletteWhenLaunched" to showToolPaletteWhenLaunched
				end tell
			else if theName is "ShowRefPaletteWhenLaunched" then
				set showRefPaletteWhenLaunched to (state of theObject is 1)
				tell user defaults
					set contents of default entry "ShowRefPaletteWhenLaunched" to showRefPaletteWhenLaunched
				end tell
			end if
		end controlClicked
		
		on openWindow()
			activate
			continue openWindow()
		end openWindow
		
		on applyDefaults()
			--log "start applyDefaults in SettingWindowController"
			selectedTab(current tab view item of tab view "SettingTabs" of my targetWindow)
			
			continue applyDefaults()
			--log "end of applyDefaults in SettingWindowController"
		end applyDefaults
		
		on prepareClose()
			set my isInitialized to false
			continue prepareClose()
		end prepareClose
		
		on saveSettingsFromWindow() -- get all values from and window and save into preference
			saveSettingsFromWindow() of TerminalSettingObj
			--log "success saveSettingsFromWindow() of TerminalSettingObj"
			saveSettingsFromWindow() of TeXCompileObj
			--log "success saveSettingsFromWindow() of TeXCompileObj"
			saveSettingsFromWindow() of PDFObj
			--log "success saveSettingsFromWindow() of PDFObj"
			saveSettingsFromWindow() of TexDocObj
			--log "success saveSettingsFromWindow() of TexDocObj"
			saveSettingsFromWindow() of dviObj
			--log "success saveSettingsFromWindow() of dviObj"
		end saveSettingsFromWindow
		
		on revertToFactorySetting()
			tell DefaultsManager
				set lifeTime to (getFactorySetting of it for "LifeTime")
				set showToolPaletteWhenLaunched to getFactorySetting of it for "ShowToolPaletteWhenLaunched"
				set showRefPaletteWhenLaunched to getFactorySetting of it for "ShowRefPaletteWhenLaunched"
			end tell
			writeSettings()
		end revertToFactorySetting
		
		on writeSettings()
			tell user defaults
				set contents of default entry "LifeTime" to lifeTime
				set contents of default entry "ShowToolPaletteWhenLaunched" to showToolPaletteWhenLaunched
				set contents of default entry "ShowRefPaletteWhenLaunched" to showRefPaletteWhenLaunched
			end tell
		end writeSettings
		
		on setmiclient()
			(*
			set currentSetting to contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of my targetWindow
			if currentSetting ends with "miclient %l %f" then
				set miclientPath to text 1 thru -7 of currentSetting
				if not (isExists(POSIX file miclientPath) of UtilityHandlers) then
					set theMessage to localized string "whereismiclient"
					set theResult to choose file with prompt theMessage without invisibles
					saveMxdviEditor((POSIX path of theResult) & " %l %f")
				end if
			else
				set prefFolderPath to path to preferences from user domain as Unicode text
				set miclientSetting to POSIX path of (prefFolderPath & "mi:mode:TEX:miclient %l %f")
				saveMxdviEditor(miclientSetting)
			end if
			*)
			tell main bundle
				set miclientPath to resource path & "/miclient"
				--set miclientPath to path for resource "miclient"
			end tell
			saveMxdviEditor(miclientPath & " -b %l %f")
		end setmiclient
		
		on saveMxdviEditor(theSetting)
			if theSetting is missing value then
				set theSetting to contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of my targetWindow
			else
				set contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of my targetWindow to theSetting
			end if
			if theSetting is not "" then
				set theCommand to "defaults write Mxdvi MxdviEditor " & (quoted form of theSetting)
				--log theCommand
				do shell script theCommand
			end if
		end saveMxdviEditor
	end script
	return SettingWindowController
end makeObj