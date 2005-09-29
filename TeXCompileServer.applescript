property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property ShellUtils : load script file (LibraryFolder & "ShellUtils")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer")
property PathConverter : load script file (LibraryFolder & "PathConverter")
property KeyValueDictionary : load script file (LibraryFolder & "KeyValueDictionary")
property StringEngine : PathConverter
property appController : missing value

property miAppRef : missing value

(*=== shared constants ===*)
property dQ : ASCII character 34
property yenmark : ASCII character 92
property comDelim : return
property sQ : missing value
property eQ : missing value

(*=== dynamically loaded script objects ===*)
property TerminalSettingObj : missing value
property UtilityHandlers : missing value
property MessageUtility : missing value
property DefaultsManager : missing value
property ToolPaletteController : missing value
property SettingWindowController : missing value
property LogFileParser : missing value
property ReplaceInputObj : missing value
property EditCommands : missing value
property TerminalCommander : missing value
property TeXCompileObj : missing value
property PDFObj : missing value
property TexDocObj : missing value
property dviObj : missing value
property RefPanelController : missing value
property SheetManager : missing value

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

(* events of application*)
on launched theObject
	--log "start lanunched"
	set showToolPaletteWhenLaunched to contents of default entry "ShowToolPaletteWhenLaunched" of user defaults
	if showToolPaletteWhenLaunched then
		showStartupMessage("opening Tool Palette ...")
		openWindow() of ToolPaletteController
	end if
	
	set showRefPaletteWhenLaunched to contents of default entry "ShowRefPaletteWhenLaunched" of user defaults
	if showRefPaletteWhenLaunched then
		showStartupMessage("opening Reference Palette ...")
		openWindow() of RefPanelController
	end if
	hide window "Startup"
	
	(*debug code*)
	(*open window*)
	--openWindow() of RefPanelController
	--openWindow() of ToolPaletteController
	--openWindow() of SettingWindowController
	
	
	(*exec tex commands*)
	--open "quickTypesetAndPreview"
	--logParseOnly() of TeXCompileObj
	--openRelatedFile of EditCommands without revealOnly
	--dviPreview() of TeXCompileObj
	--pdfPreview() of TeXCompileObj
	--execmendex() of TeXCompileObj
	--openParentFile() of EditCommands
	--seekExecEbb() of TeXCompileObj
	--dviToPDF() of TeXCompileObj
	--dviToPS() of TeXCompileObj
	--dviPreview() of TeXCompileObj
	--doTypeSet() of TeXCompileObj
	--typesetAndPreview() of TeXCompileObj
	--debug()
	--checkmifiles with saving
	
	(*misc*)
	--set theResult to call method "smartActivate:" with parameter "trmx"
	--showErrorInFrontmostApp("1111", "hello") of MessageUtility
	--openRelatedFile with revealOnly
	--open "replaceInput"
	--call method "showHelp:"
	
	(*end of debug code*)
	
	--log "end of launched"
end launched

on open theObject
	--log "start open"
	stopTimer() of ToolPaletteController
	stopTimer() of RefPanelController
	if class of theObject is record then
		set theCommandID to commandID of theObject
		if theCommandID is "reverseSearch" then
			doReverseSearch(argument of theObject) of EditCommands
		end if
		
	else
		set theCommandID to theObject
		
		if theCommandID is "replaceInput" then
			if ReplaceInputObj is missing value then
				set ReplaceInputObj to importScript("ReplaceInputObj")
			end if
			do() of ReplaceInputObj
		else if theCommandID is "typesetOnly" then
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
			openWindow() of ToolPaletteController
		else if theCommandID is "ShowRefPalette" then
			openWindow() of RefPanelController
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
		showStatusMessage("") of ToolPaletteController
	end if
	restartTimer() of ToolPaletteController
	restartTimer() of RefPanelController
	return true
end open

on clicked theObject
	--log "start clicked"
	set theTag to tag of theObject
	if theTag is 1 then
		controlClicked(theObject) of TerminalSettingObj
	else if theTag is 6 then
		controlClicked(theObject) of ReplaceInputObj
	else if theTag is 7 then
		controlClicked(theObject) of PDFObj
	else
		controlClicked(theObject)
	end if
end clicked

on controlClicked(theObject)
	set theName to name of theObject
	if theName is "Reload" then
		watchmi() of RefPanelController
	else if theName is "RevertToDefault" then
		RevertToDefault() of SettingWindowController
	else if theName is "usemi" then
		setmiclient() of SettingWindowController
	else if theName is "saveMxdviEditor" then
		saveMxdviEditor(missing value) of SettingWindowController
	end if
end controlClicked

on double clicked theObject
	doubleClicked(theObject) of RefPanelController
end double clicked

on choose menu item theObject
	--log "start choose menu item"
	set theName to name of theObject
	if theName is "Preference" then
		openWindow() of SettingWindowController
	else if theName is "ShowToolPalette" then
		openWindow() of ToolPaletteController
	else if theName is "ShowRefPalette" then
		openWindow() of RefPanelController
	end if
end choose menu item

on will finish launching theObject
	--activate
	--log "start will finish launching"
	set appController to call method "sharedAppController" of class "AppController"
	set MessageUtility to importScript("MessageUtility")
	set sQ to localized string "startQuote"
	set eQ to localized string "endQuote"
	
	showStartupMessage("Loading Factory Settings ...")
	set DefaultsManager to importScript("DefaultsManager")
	
	showStartupMessage("Loading Scripts ...")
	set UtilityHandlers to importScript("UtilityHandlers")
	set LogFileParser to importScript("LogFileParser")
	set EditCommands to importScript("EditCommands")
	set PDFObj to importScript("PDFObj")
	set TeXCompileObj to importScript("TeXCompileObj")
	set TexDocObj to importScript("TeXDocObj")
	set dviObj to importScript("DVIObj")
	set SettingWindowController to importScript("SettingWindowController")
	set ToolPaletteController to importScript("ToolPaletteController")
	set TerminalCommander to importScript("TerminalCommander")
	set TerminalSettingObj to importScript("TerminalSettingObj")
	set RefPanelController to importScript("RefPanelController")
	set SheetManager to importScript("SheetManager")
	
	--log "end of import library"
	showStartupMessage("Loading Preferences ...")
	
	--log "start of initializeing PDFObj"
	loadSettings() of PDFObj
	
	--log "start of initilizing TerminalSettingObj"
	loadSettings() of TerminalSettingObj
	--log "end of setting TerminalSettingObj"
	
	set miAppRef to path to application "mi" as alias
	--log "end sill finish launching"
end will finish launching

on awake from nib theObject
	--log "start awake from nib"
	--set theName to name of theObject
	set theClass to class of theObject
	if theClass is data source then
		tell theObject
			make new data column at the end of the data columns with properties {name:"keyword"}
			make new data column at the end of the data columns with properties {name:"replace"}
		end tell
	end if
end awake from nib

on selected tab view item theObject tab view item tabViewItem
	selectedTab(tabViewItem) of SettingWindowController
end selected tab view item

on end editing theObject
	--log "start end editing"
	set theTag to tag of theObject
	if theTag is 1 then
		endEditing(theObject) of TerminalSettingObj
	end if
end end editing

on selection changed theObject
	selectionChanged(theObject) of ReplaceInputObj
end selection changed

on should selection change theObject
	return shouldSelectionChange(theObject) of ReplaceInputObj
end should selection change

on showStartupMessage(theMessage)
	set contents of text field "StartupMessage" of window "Startup" to theMessage
end showStartupMessage

