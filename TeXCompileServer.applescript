property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property ShellUtils : load script file (LibraryFolder & "ShellUtils")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer")
property TerminalCommander : load script file (LibraryFolder & "TerminalCommander")
property PathConverter : load script file (LibraryFolder & "PathConverter")

property lifeTime : 60 -- minutes
property FreeTime : 0
property isLaunched : false

property dQ : ASCII character 34
property yenmark : ASCII character 92
property comDelim : return

property TerminalSettingObj : missing value
property UtilityHandlers : missing value
property MessageUtility : missing value

property LogFileParser : missing value
property EditCommands : missing value
property TeXCompileObj : missing value


on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on initilize()
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
		
		set TeXCompileObj to importScript("TeXCompileObj")
		set texCommandsBox of TeXCompileObj to box "TeXCommands" of window "Setting"
		set dviPreviewBox of TeXCompileObj to box "DVIPreview" of window "Setting"
		loadSettings(FactorySetting) of TeXCompileObj
		
		set TerminalSettingObj to importScript("TerminalSettingObj")
		set terminalSettingBox of TerminalSettingObj to box "TerminalSetting" of window "Setting"
		loadSettings() of TerminalSettingObj
		
		loadSettings(FactorySetting)
		center window "Setting"
		set isLaunched to true
	end if
end initilize

(* events of application*)
on launched theObject
	initilize()
	(*debug code*)
	--openParentFile() of EditCommands
	--seekExecEbb() of TeXCompileObj
	--quickTypesetAndPreview()
	--dviToPDF()
	--dviPreview() of TeXCompileObj
	--doTypeSet() of TeXCompileObj
	--openRelatedFile with revealOnly
	--show window "Setting"
	--debug()
	--open "quickTypesetAndPreview"
	--checkmifiles with saving
	(*end of debug code*)
end launched

on open theCommandID
	initilize()
	
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
	
	tell theObject
		set contents of text field "LifeTime" to lifeTime as integer
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
	end if
end choose menu item

(* read and write defaults ===============================================*)

on loadSettings()
	set lifeTime to readDefaultValue("LifeTime", lifeTime) of UtilityHandlers
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
	saveSettingsFromWindow() of TeXCompileObj
	
	tell window "Setting"
		set theLifeTime to (contents of text field "LifeTime") as string
		if theLifeTime is not "" then
			set lifeTime to theLifeTime as integer
		end if
	end tell
	
	writeSettings()
end saveSettingsFromWindow
(* end: handlers get values from window ===============================================*)

