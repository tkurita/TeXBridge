property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property ShellUtils : load script file (LibraryFolder & "ShellUtils")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer")
property TerminalCommander : load script file (LibraryFolder & "TerminalCommander")
property PathConverter : load script file (LibraryFolder & "PathConverter")
property StringEngine : PathConverter

property lifeTime : missing value -- second
property idleTime : 60 --second
property showToolPaletteWhenLaunched : true
property showRefPaletteWhenLaunched : false

property FreeTime : 0
property texCommandsBox : missing value
property miAppRef : missing value

(* shared constants*)
property dQ : ASCII character 34
property yenmark : ASCII character 92
property comDelim : return
property sQ : missing value
property eQ : missing value

property TerminalSettingObj : missing value
property UtilityHandlers : missing value
property MessageUtility : missing value
property DefaultsManager : missing value
property WindowController : missing value
property ToolPaletteController : missing value

property SettingWindowController : missing value
property LogFileParser : missing value
property EditCommands : missing value
property TeXCompileObj : missing value
property PDFObj : missing value
property TexDocObj : missing value
property dviObj : missing value

property settingWindow : missing value
property WorkspaceObj : missing value

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
	
	showStartupMessage("checking UI Elements Scripting ...")
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
	
	showStartupMessage("Loading Factory Settings ...")
	set DefaultsManager to importScript("DefaultsManager")
	loadFactorySettings("FactorySettings") of DefaultsManager
	
	showStartupMessage("Loading Scripts ...")
	set UtilityHandlers to importScript("UtilityHandlers")
	set LogFileParser to importScript("LogFileParser")
	set EditCommands to importScript("EditCommands")
	set PDFObj to importScript("PDFObj")
	set TeXCompileObj to importScript("TeXCompileObj")
	set TexDocObj to importScript("TeXDocObj")
	set dviObj to importScript("DVIObj")
	set WindowController to importScript("WindowController")
	set SettingWindowController to importScript("SettingWindowController")
	set SettingWindowController to makeObj(window "Setting") of SettingWindowController
	set ToolPaletteController to makeObj(window "ToolPalette") of WindowController
	set TerminalSettingObj to importScript("TerminalSettingObj")
	
	--log "end of import library"
	showStartupMessage("Loading Preferences ...")
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
	loadSettings() of TerminalSettingObj
	--log "end of setting TerminalSettingObj"
	
	loadSettings()
	
	set miAppRef to path to application "mi" as alias
	set WorkspaceObj to call method "sharedWorkspace" of class "NSWorkspace"
	--log "end of initialize"
end initialize

(* events of application*)
on launched theObject
	--log "start lanunched"
	--activate
	(*debug code*)
	--display alert "hello"
	--showErrorInFrontmostApp("1111", "hello") of MessageUtility
	--dviPreview() of TeXCompileObj
	--openWindow() of SettingWindowController
	--pdfPreview() of TeXCompileObj
	--call method "showHelp:"
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
		showStartupMessage("opening Tool Palette ...")
		openWindow() of ToolPaletteController
	end if
	if showRefPaletteWhenLaunched then
		showStartupMessage("opening Reference Palette ...")
		showRefPalette()
	end if
	hide window "Startup"
end launched

on open theObject
	--log "start open"
	set FreeTime to 0
	if class of theObject is record then
		set theCommandID to commandID of theObject
		if theCommandID is "updateVisibleRefPalette" then
			set visibleRefPalette of TeXCompileObj to argument of theObject
		else if theCommandID is "reverseSearch" then
			doReverseSearch(argument of theObject)
		end if
		
	else
		set theCommandID to theObject
		
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
		else if theCommandID is "pdfPreview" then
			pdfPreview() of TeXCompileObj
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
			openWindow() of SettingWindowController
		else if theCommandID is "Help" then
			call method "showHelp:"
		else if theCommandID is "ShowToolPalette" then
			--showToolPalette()
			openWindow() of ToolPaletteController
		else if theCommandID is "ShowRefPalette" then
			showRefPalette()
		else if theCommandID starts with "." then
			openOutputHadler(theCommandID) of TeXCompileObj
		else if theCommandID ends with ".tex" then
			--ignoring application responses
			tell application "Finder"
				open theCommandID using miAppRef
			end tell
			--end ignoring
			tell user defaults
				set targetLine to contents of default entry "SourcePosition"
			end tell
			doReverseSearch(targetLine)
		end if
	end if
	
	
	--display dialog theCommandID
	
	return true
end open

on idle theObject
	set FreeTime to FreeTime + idleTime
	if FreeTime > lifeTime then
		quit
	end if
	return idleTime
end idle

on clicked theObject
	set FreeTime to 0
	set theName to name of theObject
	set windowName to name of window of theObject
	
	if windowName is "ToolPalette" then
		open theName
	else
		if theName is "OKButton" then
			saveSettingsFromWindow() of SettingWindowController
			closeWindow() of SettingWindowController
		else if theName is "CancelButton" then
			closeWindow() of SettingWindowController
		else if theName is "ApplyColors" then
			applyColorsToTerminal() of TerminalSettingObj
		else if theName is "RevertColors" then
			revertColorsToTerminal() of TerminalSettingObj
		else if theName is "Save" then
			saveSettingsFromWindow() of SettingWindowController
		else if theName is "usemi" then
			setmiclient() of SettingWindowController
		else if theName is "saveMxdviEditor" then
			saveMxdviEditor(missing value) of SettingWindowController
		else if theName is "AdobeReader" then
			try
				findAdobeReaderApp() of PDFObj
			on error errMsg number -128
				setSettingToWindow() of PDFObj
				set theMessage to localized string "PDFPreviewIsInvalid"
				showMessage(theMessage) of MessageUtility
			end try
			
		else if theName is "Acrobat" then
			try
				findAcrobatApp() of PDFObj
			on error errMsg number -128
				setSettingToWindow() of PDFObj
				set theMessage to localized string "PDFPreviewIsInvalid"
				showMessage(theMessage) of MessageUtility
			end try
			
		end if
	end if
end clicked

on choose menu item theObject
	set FreeTime to 0
	set theName to name of theObject
	if theName is "Preference" then
		openWindow() of SettingWindowController
	else if theName is "ShowToolPalette" then
		openWindow() of ToolPaletteController
	else if theName is "ShowRefPalette" then
		showRefPalette()
	end if
end choose menu item

on will close theObject
	set theName to name of theObject
	
	if theName is "Setting" then
		prepareClose() of SettingWindowController
	else if theName is "ToolPalette" then
		prepareClose() of ToolPaletteController
	end if
end will close

on should zoom theObject proposed bounds proposedBounds
	set FreeTime to 0
	set theName to name of theObject
	
	if theName is "Setting" then
		return toggleCollapseWIndow() of SettingWindowController
	else if theName is "ToolPalette" then
		return toggleCollapsePanel() of ToolPaletteController
	end if
end should zoom

on will resize theObject proposed size proposedSize
	return size of theObject
end will resize

on will finish launching theObject
	--activate
	--log "start will finish launching"
	initialize()
	--log "end sill finish launching"
end will finish launching

on awake from nib theObject
	set theName to name of theObject
	if theName is "ToolPalette" then
		set hides when deactivated of theObject to false
	end if
end awake from nib

on will quit theObject
	if isOpened of SettingWindowController then
		prepareClose() of SettingWindowController
	end if
	if isOpened of ToolPaletteController then
		prepareClose() of ToolPaletteController
	end if
end will quit

on will open theObject
	set theName to name of theObject
	
	if theName is "Startup" then
		set level of theObject to 1
		center theObject
		set alpha value of theObject to 0.7
	end if
end will open

on showStartupMessage(theMessage)
	set contents of text field "StartupMessage" of window "Startup" to theMessage
end showStartupMessage

on loadSettings()
	tell DefaultsManager
		set lifeTime to (readDefaultValue("LifeTime") of it)
		set showToolPaletteWhenLaunched to readDefaultValue("ShowToolPaletteWhenLaunched") of it
		set showRefPaletteWhenLaunched to readDefaultValue("ShowRefPaletteWhenLaunched") of it
	end tell
end loadSettings

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

on doReverseSearch(targetLine)
	tell application "System Events"
		tell application process "mi"
			keystroke "b" using command down
		end tell
	end tell
	--ignoring application responses
	tell application "mi"
		select paragraph targetLine of first document
	end tell
	--end ignoring
end doReverseSearch
