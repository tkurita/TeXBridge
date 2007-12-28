--property loader : proxy_with({autocollect:true}) of application (get "TeXToolsLib")
property loader : proxy() of application (get "TeXToolsLib")

on load(a_name)
	return loader's load(a_name)
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

on import_script(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end import_script

script ScriptImporter
	on do(scriptName)
		return import_script(scriptName)
	end do
end script

(* events of application*)
on launched theObject
	--log "start lanunched"
	set showToolPaletteWhenLaunched to contents of default entry "ShowToolPaletteWhenLaunched" of user defaults
	set IsOpenedToolPalette to value_with_default("IsOpenedToolPalette", showToolPaletteWhenLaunched) of DefaultsManager
	if not showToolPaletteWhenLaunched then
		set showToolPaletteWhenLaunched to IsOpenedToolPalette
	end if
	if showToolPaletteWhenLaunched then
		show_startup_message("Opening Tool Palette ...")
		open_window() of ToolPaletteController
	end if
	
	set showRefPaletteWhenLaunched to contents of default entry "ShowRefPaletteWhenLaunched" of user defaults
	set IsOpenedRefPalette to value_with_default("IsOpenedRefPalette", showRefPaletteWhenLaunched) of DefaultsManager
	if not showRefPaletteWhenLaunched then
		set showRefPaletteWhenLaunched to IsOpenedRefPalette
	end if
	if showRefPaletteWhenLaunched then
		show_startup_message("Opening Reference Palette ...")
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
	--set a_result to call method "activateAppOfType:" of class "SmartActivate" with parameter "trmx"
	--showErrorInFrontmostApp("1111", "hello") of MessageUtility
	--openRelatedFile with revealOnly
	--open "ReplaceInput"
	--call method "showHelp:"
	--call method "currentDocumentMode" of class "EditorClient"
	--open {commandClass:"editSupport", commandID:"openRelatedFile"}
	(*end of debug code*)
	
	--log "end of launched"
end launched

on do_replaceinput(arg)
	ReplaceInput's do()
end do_replaceinput

on open theObject
	--log "start open"
	stop_timer() of RefPanelController
	--call method "temporaryStopDisplayToggleTimer" of WindowVisibilityController
	set a_class to class of theObject
	if a_class is record then
		set command_class to commandClass of theObject
		if command_class is "action" then
			theObject's commandScript's do(me, {})
		else if command_class is "compile" then
			try
				theObject's commandScript's do(CompileCenter, {})
			on error msg number errno
				if errno is in {1700, 1710, 1720} then -- errors related to access com.apple.Terminal 
					showError(errno, "open", msg) of MessageUtility
				else
					error msg number errno
				end if
			end try
			show_status_message("") of ToolPaletteController
			
		else if command_class is "editSupport" then
			theObject's commandScript's do(EditCommands, {})
		else
			showMessage("Unknown commandClass : " & command_class) of MessageUtility
		end if
	else
		set command_id to theObject
		
		if command_id starts with "." then
			openOutputHadler(command_id) of CompileCenter
			(*
		else if command_id ends with ".tex" then
			
			EditorClient's open_with_activating(command_id)
			tell user defaults
				set targetLine to contents of default entry "SourcePosition"
			end tell
			doReverseSearch(targetLine)
		*)
		else
			showMessage("Unknown argument : " & command_id) of MessageUtility
		end if
		
	end if
	
	restart_timer() of RefPanelController
	--call method "restartStopDisplayToggleTimer" of WindowVisibilityController
	return true
end open

on clicked theObject
	--log "start clicked"
	set a_tag to tag of theObject
	if a_tag is 1 then
		control_clicked(theObject) of TerminalSettingObj
	else if a_tag is 6 then
		control_clicked(theObject) of ReplaceInput
	else if a_tag is 7 then
		control_clicked(theObject) of PDFController
	else
		control_clicked(theObject)
	end if
end clicked

on control_clicked(theObject)
	set a_name to name of theObject
	if a_name is "Reload" then
		watchmi of RefPanelController with force_reloading
	else if a_name is "RevertToDefault" then
		RevertToDefault() of SettingWindowController
	else if a_name is "usemi" then
		setmiclient() of SettingWindowController
	else if a_name is "saveMxdviEditor" then
		saveMxdviEditor(missing value) of SettingWindowController
	end if
end control_clicked

on double clicked theObject
	double_clicked(theObject) of RefPanelController
end double clicked

on choose menu item theObject
	--log "start choose menu item"
	set a_name to name of theObject
	if a_name is "Preference" then
		open_window() of SettingWindowController
	else if a_name is "ShowToolPalette" then
		open_window() of ToolPaletteController
	else if a_name is "ShowRefPalette" then
		open_window() of RefPanelController
	end if
end choose menu item

on setup_constants()
	set app_file to EditorClient's application_file()
	tell application "System Events"
		set a_var to version of app_file
	end tell
	set a_var to word 3 of a_var
	if a_var is greater than or equal to "2.1.7" then
		set plistName to "ToolSupport"
	else
		set plistName to "ToolSupport216"
	end if
	
	tell main bundle
		set plistPath to path for resource plistName extension "plist"
	end tell
	set constantsDict to call method "dictionaryWithContentsOfFile:" of class "NSDictionary" with parameter plistPath
	set _backslash to backslash of constantsDict
end setup_constants

on will finish launching theObject
	--activate
	--log "start will finish launching"
	set appController to call method "sharedAppController" of class "AppController"
	show_startup_message("Loading Factory Settings ...")
	set MessageUtility to import_script("MessageUtility")
	
	
	set DefaultsManager to import_script("DefaultsManager")
	
	show_startup_message("Loading Scripts ...")
	set UtilityHandlers to import_script("UtilityHandlers")
	set LogFileParser to import_script("LogFileParser")
	set EditCommands to import_script("EditCommands")
	set PDFController to import_script("PDFController")
	set CompileCenter to import_script("CompileCenter")
	set TeXDocController to import_script("TeXDocController")
	set DVIController to import_script("DVIController")
	set SettingWindowController to import_script("SettingWindowController")
	set ToolPaletteController to import_script("ToolPaletteController")
	set TerminalCommander to make_obj() of (import_script("TerminalCommander"))
	set TerminalSettingObj to import_script("TerminalSettingObj")
	set RefPanelController to import_script("RefPanelController")
	set SheetManager to import_script("SheetManager")
	set AuxData to import_script("AuxData")
	set EditorClient to import_script("EditorClient")
	set ReplaceInput to import_script("ReplaceInput")
	
	--log "end of import library"
	show_startup_message("Loading Preferences ...")
	setup_constants()
	--log "start of initializeing PDFController"
	loadSettings() of PDFController
	
	--log "start of initilizing TerminalSettingObj"
	loadSettings() of TerminalSettingObj
	--log "end will finish launching"
end will finish launching

on awake from nib theObject
	--log "start awake from nib"
	set a_class to class of theObject
	if a_class is data source then
		tell theObject
			make new data column at the end of the data columns with properties {name:"keyword"}
			make new data column at the end of the data columns with properties {name:"replace"}
		end tell
	else
		set a_tag to tag of theObject
		if a_tag is 6 then
			ReplaceInput's set_gui_element(theObject)
		end if
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
	selection_changed(theObject) of ReplaceInput
end selection changed

on should selection change theObject
	return should_selection_change(theObject) of ReplaceInput
end should selection change

on will quit theObject
	tell user defaults
		set contents of default entry "IsOpenedToolPalette" to is_opened() of ToolPaletteController
		set contents of default entry "IsOpenedRefPalette" to is_opened() of RefPanelController
	end tell
end will quit

on cell value changed theObject row theRow table column tableColumn value theValue
	--log "start cell value changed"
	set a_name to name of theObject
	if a_name is "UserReplaceTable" then
		ReplaceInput's cell_value_changed(theObject, theRow, tableColumn, theValue)
	end if
end cell value changed

on show_startup_message(a_msg)
	set contents of text field "StartupMessage" of window "Startup" to a_msg
end show_startup_message