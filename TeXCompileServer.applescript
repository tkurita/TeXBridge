property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property ShellUtils : load script file (LibraryFolder & "ShellUtils")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer")
property TerminalCommander : load script file (LibraryFolder & "TerminalCommander")
property PathConverter : load script file (LibraryFolder & "PathConverter")
property StringEngine : PathConverter

property lifeTime : 60 -- minutes
property showToolPaletteWhenLaunched : true
property showRefPaletteWhenLaunched : false

property FreeTime : 0
property settingWindowBounds : {}
property texCommandsBox : missing value

property dQ : ASCII character 34
property yenmark : ASCII character 92
property comDelim : return
property sQ : missing value
property eQ : missing value

property TerminalSettingObj : missing value
property UtilityHandlers : missing value
property MessageUtility : missing value

property LogFileParser : missing value
property EditCommands : missing value
property TeXCompileObj : missing value
property PDFObj : missing value
property TexDocObj : missing value
property dviObj : missing value

property settingWindow : missing value

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on initialize()
	--log "start initialize"
	set MessageUtility to importScript("MessageUtility")
	set sQ to localized string "startQuote"
	set eQ to localized string "endQuote"
	
	tell application "System Events"
		set UIScriptFlag to UI elements enabled
	end tell
	if not (UIScriptFlag) then
		set theMessage to localized string "disableUIScripting"
		tell application "System Preferences"
			activate
			set current pane to pane "com.apple.preference.universalaccess"
			display dialog theMessage buttons {"OK"} default button "OK"
		end tell
		quit
	end if
	
	set FactorySetting to importScript("FactorySetting")
	set UtilityHandlers to importScript("UtilityHandlers")
	set LogFileParser to importScript("LogFileParser")
	set EditCommands to importScript("EditCommands")
	set PDFObj to importScript("PDFObj")
	set TeXCompileObj to importScript("TeXCompileObj")
	set TexDocObj to importScript("TeXDocObj")
	set dviObj to importScript("DVIObj")
	set TerminalSettingObj to importScript("TerminalSettingObj")
	
	--log "end of import library"
	
	set texCommandsBox to tab view item "TeXCommands" of tab view "SettingTabs" of window "Setting"
	
	loadSettings() of TeXCompileObj
	--log "end of setting TeXCompileObj"
	
	loadSettings() of TexDocObj
	
	set dviPreviewBox of dviObj to tab view item "PreviewSetting" of tab view "SettingTabs" of window "Setting"
	loadSettings() of dviObj
	
	--log "start of initializeing PDFObj"
	set pdfPreviewBox of PDFObj to tab view item "PreviewSetting" of tab view "SettingTabs" of window "Setting"
	--log "loadSettings() of PDFObj"
	loadSettings() of PDFObj
	
	--log "start of initilizing TerminalSettingObj"
	set terminalSettingBox of TerminalSettingObj to tab view item "TerminalSetting" of tab view "SettingTabs" of window "Setting"
	loadSettings(FactorySetting) of TerminalSettingObj
	--log "end of setting TerminalSettingObj"
	
	loadSettings()
	
	--center window "Setting"
end initialize

(* events of application*)
on launched theObject
	(*debug code*)
	--execmendex() of TeXCompileObj
	--showToolPalette()
	--openParentFile() of EditCommands
	--seekExecEbb() of TeXCompileObj
	--quickTypesetAndPreview() of TeXCompileObj
	--dviToPDF() of TeXCompileObj
	--dviPreview() of TeXCompileObj
	--doTypeSet() of TeXCompileObj
	
	--typesetAndPreview() of TeXCompileObj
	--openRelatedFile with revealOnly
	--show window "Setting"
	--debug()
	--open "quickTypesetAndPreview"
	--checkmifiles with saving
	--log "end of launched"
	(*end of debug code*)
	if showToolPaletteWhenLaunched then
		showToolPalette()
	end if
	if showRefPaletteWhenLaunched then
		showRefPalette()
	end if
end launched

on open theCommandID
	--log "start open"
	
	if theCommandID is "typesetOnly" then
		doTypeSet() of TeXCompileObj
	else if theCommandID is "typesetAndPreview" then
		typesetAndPreview() of TeXCompileObj
	else if theCommandID is "quickTypesetAndPreview" then
		quickTypesetAndPreview() of TeXCompileObj
	else if theCommandID is "typesetAndPDFPreview" then
		typesetAndPDFPreview() of TeXCompileObj
	else if theCommandID is "dviPreview" then
		dviPreview() of TeXCompileObj
	else if theCommandID is "bibTex" then
		bibTex() of TeXCompileObj
	else if theCommandID is "dviToPDF" then
		dviToPDF() of TeXCompileObj
	else if theCommandID is "seekExecEbb" then
		seekExecEbb() of TeXCompileObj
	else if theCommandID is "dvips" then
		dviToPS() of TeXCompileObj
	else if theCommandID is "mendex" then
		execmendex() of TeXCompileObj
	else if theCommandID is "openRelatedFile" then
		openRelatedFile of EditCommands without revealOnly
	else if theCommandID is "revealRelatedFile" then
		openRelatedFile of EditCommands with revealOnly
	else if theCommandID is "openParentFile" then
		openParentFile() of EditCommands
	else if theCommandID is "setting" then
		activate
		show window "Setting"
	else if theCommandID is "Help" then
		call method "showHelp:"
	else if theCommandID is "ShowToolPalette" then
		showToolPalette()
	else if theCommandID is "ShowRefPalette" then
		showRefPalette()
	else if theCommandID starts with "." then
		openOutputHadler(theCommandID) of TeXCompileObj
	end if
	--display dialog theCommandID
	set FreeTime to 0
	return true
end open

on idle theObject
	set FreeTime to FreeTime + 1
	if FreeTime > lifeTime then
		quit
	end if
	return 60
end idle

on will open theObject
	--log "start will open"
	setSettingToWindow() of TerminalSettingObj
	setSettingToWindow() of TeXCompileObj
	setSettingToWindow() of PDFObj
	setSettingToWindow() of TexDocObj
	setSettingToWindow() of dviObj
	set settingWindow to theObject
	
	--The other setting
	set theOtherSettingTab to tab view item "TheOtherSetting" of tab view "SettingTabs" of theObject
	set contents of text field "LifeTime" of theOtherSettingTab to lifeTime as integer
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
	
	tell theObject
		--MxdviEditor
		set currentMxdviEditor to do shell script "defaults read Mxdvi MxdviEditor"
		set contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" to currentMxdviEditor
		
		--set window position
		if settingWindowBounds is not {} then
			set bounds to settingWindowBounds
		else
			center
		end if
	end tell
end will open

on clicked theObject
	set theName to name of theObject
	if theName is "OKButton" then
		saveSettingsFromWindow()
		hide window of theObject
	else if theName is "CancelButton" then
		hide window of theObject
	else if theName is "ApplyColors" then
		applyColorsToTerminal() of TerminalSettingObj
	else if theName is "RevertColors" then
		revertColorsToTerminal() of TerminalSettingObj
	else if theName is "Save" then
		saveSettingsFromWindow()
	else if theName is "usemi" then
		setmiclient()
	else if theName is "saveMxdviEditor" then
		saveMxdviEditor(missing value)
	end if
end clicked

on setmiclient()
	set currentSetting to contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of settingWindow
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
		set theSetting to contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of settingWindow
	else
		set contents of text field "MxdviEditorSetting" of tab view item "PreviewSetting" of tab view "SettingTabs" of settingWindow to theSetting
	end if
	set theCommand to "defaults write Mxdvi MxdviEditor " & (quoted form of theSetting)
	--log theCommand
	do shell script theCommand
end saveMxdviEditor

on choose menu item theObject
	set theName to name of theObject
	if theName is "Preference" then
		show window "Setting"
	else if theName is "ShowToolPalette" then
		showToolPalette()
	else if theName is "ShowRefPalette" then
		showRefPalette()
	end if
end choose menu item

on will close theObject
	set settingWindowBounds to bounds of theObject
	tell user defaults
		set contents of default entry "SettingWindowBounds" to settingWindowBounds
	end tell
end will close

on will finish launching theObject
	--activate
	--log "start will finish launching"
	initialize()
	--log "end sill finish launching"
end will finish launching

(* read and write defaults ===============================================*)

on loadSettings()
	tell UtilityHandlers
		set lifeTime to readDefaultValue("LifeTime", lifeTime) of it
		set settingWindowBounds to readDefaultValue("SettingWindowBounds", settingWindowBounds) of it
		set showToolPaletteWhenLaunched to readDefaultValue("ShowToolPaletteWhenLaunched", showToolPaletteWhenLaunched) of it
		set showRefPaletteWhenLaunched to readDefaultValue("ShowRefPaletteWhenLaunched", showRefPaletteWhenLaunched) of it
	end tell
end loadSettings

on writeSettings()
	tell user defaults
		set contents of default entry "LifeTime" to lifeTime
		set contents of default entry "ShowToolPaletteWhenLaunched" to showToolPaletteWhenLaunched
		set contents of default entry "ShowRefPaletteWhenLaunched" to showRefPaletteWhenLaunched
	end tell
end writeSettings
(* end : read and write defaults ===============================================*)

(* handlers get values from window ===============================================*)
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
	set theOtherSettingTab to tab view item "TheOtherSetting" of tab view "SettingTabs" of window "Setting"
	set theLifeTime to (contents of text field "LifeTime" of theOtherSettingTab) as string
	
	if theLifeTime is not "" then
		set lifeTime to theLifeTime as integer
	end if
	set showToolPaletteWhenLaunched to (state of button "ShowToolPaletteWhenLaunched" of theOtherSettingTab is 1)
	set showRefPaletteWhenLaunched to (state of button "ShowRefPaletteWhenLaunched" of theOtherSettingTab is 1)
	writeSettings()
end saveSettingsFromWindow
(* end: handlers get values from window ===============================================*)

on showToolPalette()
	tell main bundle
		set ToolPalettePath to path for resource "ToolPalette" extension "app"
	end tell
	tell application ((POSIX file ToolPalettePath) as Unicode text)
		launch
	end tell
end showToolPalette

on showRefPalette()
	tell main bundle
		set refPalettePath to path for resource "ReferencePalette" extension "app"
	end tell
	ignoring application responses
		tell application ((POSIX file refPalettePath) as Unicode text)
			--launch
			open {commandID:"openRefPalette"}
		end tell
	end ignoring
end showRefPalette
