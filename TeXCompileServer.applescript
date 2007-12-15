--property loader : proxy_with({autocollect:true}) of application (get "TeXToolsLib")
property loader : proxy() of application (get "TeXToolsLib")

on load(theName)
	return loader's load(theName)
end load

property ShellUtils : load("ShellUtils")
property PathConverter : load("PathConverter")
property XDict : load("XDict")
property XFile : load("XFile")
property XList : XDict's XList
property XText : load("XText")
property PathAnalyzer : XFile's PathAnalyzer
property StringEngine : PathConverter's StringEngine
property FrontDocument : load("FrontDocument")
property TerminalCommanderBase : load("TerminalCommander")

property appController : missing value
--property WindowVisibilityController : missing value

property miAppRef : missing value

(*=== shared constants ===*)
property dQ : ASCII character 34
property _backslash : missing value
property yenmark : ASCII character 92
property comDelim : return

property constantsDict : missing value

(*=== dynamically loaded script objects ===*)
property TerminalSettingObj : missing value
property UtilityHandlers : missing value
property MessageUtility : missing value
property DefaultsManager : missing value
property ToolPaletteController : missing value
property SettingWindowController : missing value
property LogFileParser : missing value
property ReplaceInput : missing value
property EditCommands : missing value
property TerminalCommander : missing value
property CompileCenter : missing value
property PDFController : missing value
property TeXDocController : missing value
property DVIController : missing value
property RefPanelController : missing value
property SheetManager : missing value
property AuxData : missing value
property EditorClient : missing value

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

script ScriptImporter
	on do(scriptName)
		return importScript(scriptName)
	end do
end script

(* events of application*)
on launched theObject
	--log "start lanunched"
	set showToolPaletteWhenLaunched to contents of default entry "ShowToolPaletteWhenLaunched" of user defaults
	set IsOpenedToolPalette to readDefaultValueWith("IsOpenedToolPalette", showToolPaletteWhenLaunched) of DefaultsManager
	if not showToolPaletteWhenLaunched then
		set showToolPaletteWhenLaunched to IsOpenedToolPalette
	end if
	if showToolPaletteWhenLaunched then
		showStartupMessage("Opening Tool Palette ...")
		open_window() of ToolPaletteController
	end if
	
	set showRefPaletteWhenLaunched to contents of default entry "ShowRefPaletteWhenLaunched" of user defaults
	set IsOpenedRefPalette to readDefaultValueWith("IsOpenedRefPalette", showRefPaletteWhenLaunched) of DefaultsManager
	if not showRefPaletteWhenLaunched then
		set showRefPaletteWhenLaunched to IsOpenedRefPalette
	end if
	if showRefPaletteWhenLaunched then
		showStartupMessage("Opening Reference Palette ...")
		open_window() of RefPanelController
	end if
	hide window "Startup"
	
	(*debug code*)
	(*open window*)
	--open_window() of RefPanelController
	--open_window() of ToolPaletteController
	--open_window() of SettingWindowController
	
	
	(*exec tex commands*)
	--dvi_to_pdf({}) of CompileCenter
	--logParseOnly() of CompileCenter
	--preview_dvi({}) of CompileCenter
	--preview_pdf({}) of CompileCenter
	--mendex({}) of CompileCenter
	--open_parentfile({}) of EditCommands
	--seek_ebb({}) of CompileCenter
	--dvi_to_ps({}) of CompileCenter
	--preview_dvi({}) of CompileCenter
	--do_typeset({}) of CompileCenter
	--typeset_preview({}) of CompileCenter
	--debug()
	--checkmifiles with saving
	--quick_typeset_preview({}) of CompileCenter
	
	(*misc*)
	--set theResult to call method "activateAppOfType:" of class "SmartActivate" with parameter "trmx"
	--showErrorInFrontmostApp("1111", "hello") of MessageUtility
	--openRelatedFile with revealOnly
	--open "ReplaceInput"
	--call method "showHelp:"
	--call method "currentDocumentMode" of class "EditorClient"
	--open {commandClass:"editSupport", commandID:"openRelatedFile"}
	(*end of debug code*)
	
	--log "end of launched"
end launched

on do_replaceinput({})
	if ReplaceInput is missing value then
		set ReplaceInput to importScript("ReplaceInput")
	end if
	ReplaceInput's do()
end do_replaceinput

on open theObject
	--log "start open"
	--stopTimer() of ToolPaletteController
	stopTimer() of RefPanelController
	--call method "temporaryStopDisplayToggleTimer" of WindowVisibilityController
	set a_class to class of theObject
	if a_class is record then
		set command_class to commandClass of theObject
		if command_class is "action" then
			theObject's commandScript's do(me, {})
		else if command_class is "compile" then
			try
				theObject's commandScript's do(CompileCenter)
			on error msg number errno
				if errno is in {1700, 1710, 1720} then -- errors related to access com.apple.Terminal 
					showError(errno, "open", msg) of MessageUtility
				else
					error msg number errno
				end if
			end try
			show_status_message("") of ToolPaletteController
			
		else if command_class is "editSupport" then
			theObject's commandScript's do(EditCommands)
		else
			showMessage("Unknown commandClass : " & command_class) of MessageUtility
		end if
	else
		set command_id to theObject
		
		if command_id starts with "." then
			openOutputHadler(command_id) of CompileCenter
		else if command_id ends with ".tex" then
			--ignoring application responses
			tell application "Finder"
				open command_id using miAppRef
			end tell
			--end ignoring
			tell user defaults
				set targetLine to contents of default entry "SourcePosition"
			end tell
			doReverseSearch(targetLine)
		else
			showMessage("Unknown argument : " & command_id) of MessageUtility
		end if
		
	end if
	
	restartTimer() of RefPanelController
	--call method "restartStopDisplayToggleTimer" of WindowVisibilityController
	return true
end open

on clicked theObject
	--log "start clicked"
	set theTag to tag of theObject
	if theTag is 1 then
		controlClicked(theObject) of TerminalSettingObj
	else if theTag is 6 then
		controlClicked(theObject) of ReplaceInput
	else if theTag is 7 then
		controlClicked(theObject) of PDFController
	else
		controlClicked(theObject)
	end if
end clicked

on controlClicked(theObject)
	set theName to name of theObject
	if theName is "Reload" then
		watchmi of RefPanelController with force_reloading
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
		open_window() of SettingWindowController
	else if theName is "ShowToolPalette" then
		open_window() of ToolPaletteController
	else if theName is "ShowRefPalette" then
		open_window() of RefPanelController
	end if
end choose menu item

on setUpConstants()
	tell application "System Events"
		set theVer to version of miAppRef
	end tell
	set theVer to word 3 of theVer
	if theVer is greater than or equal to "2.1.7" then
		set plistName to "ToolSupport"
	else
		set plistName to "ToolSupport216"
	end if
	
	tell main bundle
		set plistPath to path for resource plistName extension "plist"
	end tell
	set constantsDict to call method "dictionaryWithContentsOfFile:" of class "NSDictionary" with parameter plistPath
	set _backslash to backslash of constantsDict
end setUpConstants

on will finish launching theObject
	--activate
	--log "start will finish launching"
	set appController to call method "sharedAppController" of class "AppController"
	set MessageUtility to importScript("MessageUtility")
	
	showStartupMessage("Loading Factory Settings ...")
	set miAppRef to path to application "mi" as alias
	setUpConstants()
	
	set DefaultsManager to importScript("DefaultsManager")
	
	showStartupMessage("Loading Scripts ...")
	set UtilityHandlers to importScript("UtilityHandlers")
	set LogFileParser to importScript("LogFileParser")
	set EditCommands to importScript("EditCommands")
	set PDFController to importScript("PDFController")
	set CompileCenter to importScript("CompileCenter")
	set TeXDocController to importScript("TeXDocController")
	set DVIController to importScript("DVIController")
	set SettingWindowController to importScript("SettingWindowController")
	set ToolPaletteController to importScript("ToolPaletteController")
	set TerminalCommander to make_obj() of (importScript("TerminalCommander"))
	set TerminalSettingObj to importScript("TerminalSettingObj")
	set RefPanelController to importScript("RefPanelController")
	set SheetManager to importScript("SheetManager")
	set AuxData to importScript("AuxData")
	set EditorClient to importScript("EditorClient")
	
	--log "end of import library"
	showStartupMessage("Loading Preferences ...")
	
	--log "start of initializeing PDFController"
	loadSettings() of PDFController
	
	--log "start of initilizing TerminalSettingObj"
	loadSettings() of TerminalSettingObj
	--log "end will finish launching"
end will finish launching

on awake from nib theObject
	--log "start awake from nib"
	--set theName to name of theObject
	set a_class to class of theObject
	if a_class is data source then
		tell a_class
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
	set a_tag to tag of theObject
	if a_tag is 1 then
		endEditing(theObject) of TerminalSettingObj
	end if
end end editing

on selection changed theObject
	selectionChanged(theObject) of ReplaceInput
end selection changed

on should selection change theObject
	return shouldSelectionChange(theObject) of ReplaceInput
end should selection change

on will quit theObject
	tell user defaults
		set contents of default entry "IsOpenedToolPalette" to is_opend() of ToolPaletteController
		set contents of default entry "IsOpenedRefPalette" to is_opend() of RefPanelController
	end tell
end will quit

on showStartupMessage(a_msg)
	set contents of text field "StartupMessage" of window "Startup" to a_msg
end showStartupMessage