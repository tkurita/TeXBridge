property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property ShellUtils : load script file (LibraryFolder & "ShellUtils")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer")
property TerminalCommander : load script file (LibraryFolder & "TerminalCommander")
property PathConverter : load script file (LibraryFolder & "PathConverter")

property lifeTime : 60 -- minutes
property FreeTime : 0
property isLaunched : false
property settingWindowBounds : {}
property texCommandsBox : missing value

property dQ : ASCII character 34
property yenmark : ASCII character 92
property comDelim : return

property TerminalSettingObj : missing value
property UtilityHandlers : missing value
property MessageUtility : missing value

property LogFileParser : missing value
property EditCommands : missing value
property TeXCompileObj : missing value
property PDFObj : missing value
property TexDocObj : missing value
property dviObj : missing value

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on initialize()
	--log "start initialize"
	if not isLaunched then
		set MessageUtility to importScript("MessageUtility")
		
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
		set TerminalSettingObj to importScript("TerminalSettingObj")
		set terminalSettingBox of TerminalSettingObj to tab view item "TerminalSetting" of tab view "SettingTabs" of window "Setting"
		loadSettings(FactorySetting) of TerminalSettingObj
		--log "end of setting TerminalSettingObj"
		
		loadSettings()
		
		--center window "Setting"
		set isLaunched to true
	end if
end initialize

(* events of application*)
on launched theObject
	--initialize()
	--log "end of initialize"
	(*debug code*)
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
	(*end of debug code*)
end launched

on open theCommandID
	--display dialog "open"
	--initialize()
	
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
	setSettingToWindow() of TerminalSettingObj
	setSettingToWindow() of TeXCompileObj
	setSettingToWindow() of PDFObj
	setSettingToWindow() of TexDocObj
	setSettingToWindow() of dviObj
	
	tell theObject
		set contents of text field "LifeTime" of tab view item "TheOtherSetting" of tab view "SettingTabs" of theObject to lifeTime as integer
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
	end if
end clicked

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
	initialize()
	--display dialog "will finish launch"
end will finish launching

(* read and write defaults ===============================================*)

on loadSettings()
	set lifeTime to readDefaultValue("LifeTime", lifeTime) of UtilityHandlers
	set settingWindowBounds to readDefaultValue("SettingWindowBounds", settingWindowBounds) of UtilityHandlers
	if settingWindowBounds is not {} then
		set bounds of window "Setting" to settingWindowBounds
	else
		center window "Setting"
	end if
end loadSettings

on writeSettings()
	tell user defaults
		set contents of default entry "LifeTime" to lifeTime
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
	
	set theLifeTime to (contents of text field "LifeTime" of tab view item "TheOtherSetting" of tab view "SettingTabs" of window "Setting") as string
	
	if theLifeTime is not "" then
		set lifeTime to theLifeTime as integer
	end if
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
