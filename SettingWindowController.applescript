global WindowController
global UtilityHandlers

on makeObj(theWindow)
	set theWindowController to makeObj(theWindow) of WindowController
	
	script SettingWindowController
		(* shared script object *)
		global TerminalSettingObj
		global TeXCompileObj
		global PDFObj
		global TexDocObj
		global dviObj
		
		(* shared variable *)
		global lifeTime
		global showToolPaletteWhenLaunched
		global showRefPaletteWhenLaunched
		
		property parent : theWindowController
		property theOtherSettingTab : missing value
		
		on initialize()
			set theOtherSettingTab to tab view item "TheOtherSetting" of tab view "SettingTabs" of my targetWindow
			continue initialize()
		end initialize
		
		on openWindow()
			activate
			if my isOpened then
				showWindow()
			else
				continue openWindow()
			end if
		end openWindow
		
		on applyDefaults()
			setSettingToWindow() of TerminalSettingObj
			setSettingToWindow() of TeXCompileObj
			setSettingToWindow() of PDFObj
			setSettingToWindow() of TexDocObj
			setSettingToWindow() of dviObj
			
			--log "after setSettingToWindow() of TerminalSettingObj"
			
			(* The other setting *)
			set contents of text field "LifeTime" of theOtherSettingTab to (lifeTime div 60) as integer
			if showToolPaletteWhenLaunched then
				set state of button "ShowToolPaletteWhenLaunched" of theOtherSettingTab to 1
			else
				set state of button "ShowToolPaletteWhenLaunched" of theOtherSettingTab to 0
			end if
			
			if showRefPaletteWhenLaunched then
				set state of button "ShowRefPaletteWhenLaunched" of theOtherSettingTab to 1
			else
				set state of button "ShowRefPaletteWhenLaunched" of theOtherSettingTab to 0
			end if
			
			(* MxdviEditor *)
			tell my targetWindow
				set currentMxdviEditor to do shell script "defaults read Mxdvi MxdviEditor"
				set contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" to currentMxdviEditor
			end tell
			
			continue applyDefaults()
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
			
			set theLifeTime to (contents of text field "LifeTime" of theOtherSettingTab) as string
			if theLifeTime is not "" then
				set lifeTime to (theLifeTime as integer) * 60
			end if
			
			set showToolPaletteWhenLaunched to (state of button "ShowToolPaletteWhenLaunched" of theOtherSettingTab is 1)
			set showRefPaletteWhenLaunched to (state of button "ShowRefPaletteWhenLaunched" of theOtherSettingTab is 1)
			writeSettings()
		end saveSettingsFromWindow
		
		on writeSettings()
			tell user defaults
				set contents of default entry "LifeTime" to lifeTime
				set contents of default entry "ShowToolPaletteWhenLaunched" to showToolPaletteWhenLaunched
				set contents of default entry "ShowRefPaletteWhenLaunched" to showRefPaletteWhenLaunched
			end tell
		end writeSettings
		
		on setmiclient()
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
		end setmiclient
		
		on saveMxdviEditor(theSetting)
			if theSetting is missing value then
				set theSetting to contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of my targetWindow
			else
				set contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of my targetWindow to theSetting
			end if
			set theCommand to "defaults write Mxdvi MxdviEditor " & (quoted form of theSetting)
			--log theCommand
			do shell script theCommand
		end saveMxdviEditor
	end script
	return SettingWindowController
end makeObj