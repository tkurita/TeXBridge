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
property FrontAccess : load("FrontAccess")
property TerminalCommanderBase : load("TerminalCommander")
property appController : missing value

(*=== shared constants ===*)
property _backslash : missing value
--property yenmark : ASCII character 92
property yenmark : character id 165
property _com_delim : return

property constantsDict : missing value

(*=== dynamically loaded script objects ===*)
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
property Root : me

on import_script(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end import_script

(* events of application*)
on launched theObject
	log "start lanunched"
	log "will show toolpalette"
	set showToolPaletteWhenLaunched to contents of default entry "ShowToolPaletteWhenLaunched" of user defaults
	set IsOpenedToolPalette to value_with_default("IsOpenedToolPalette", showToolPaletteWhenLaunched) of DefaultsManager
	if not showToolPaletteWhenLaunched then
		set showToolPaletteWhenLaunched to IsOpenedToolPalette
	end if
	if showToolPaletteWhenLaunched then
		show_startup_message("Opening Tool Palette ...")
		open_window() of ToolPaletteController
	end if
	
	log "will show refpalette"
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
	open_window() of SettingWindowController
	
	
	(*exec tex commands*)
	--dvi_to_pdf() of CompileCenter
	--logParseOnly() of CompileCenter
	--preview_dvi() of CompileCenter
	--preview_pdf() of CompileCenter
	--mendex() of CompileCenter
	--open_parentfile() of EditCommands
	--seek_ebb() of CompileCenter
	--dvi_to_ps() of CompileCenter
	--preview_dvi() of CompileCenter
	--do_typeset() of CompileCenter
	--typeset_preview() of CompileCenter
	--debug()
	--checkmifiles with saving
	--quick_typeset_preview() of CompileCenter
	
	(*misc*)
	--set a_result to call method "activateAppOfType:" of class "SmartActivate" with parameter "trmx"
	--openRelatedFile with revealOnly
	-- do_replaceinput()
	--call method "showHelp:"
	--call method "currentDocumentMode" of class "EditorClient"
	--open {commandClass:"editSupport", commandID:"openRelatedFile"}
	(*end of debug code*)
	
	--log "end of launched"
end launched

on do_replaceinput()
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
			theObject's commandScript's do(me)
		else if command_class is "compile" then
			try
				theObject's commandScript's do(CompileCenter)
			on error msg number errno
				if errno is in {1700, 1710, 1720} then -- errors related to access com.apple.Terminal 
					MessageUtility's show_error(errno, "open", msg)
				else
					error msg number errno
				end if
			end try
			show_status_message("") of ToolPaletteController
			
		else if command_class is "editSupport" then
			theObject's commandScript's do(EditCommands)
		else
			show_message("Unknown commandClass : " & command_class) of MessageUtility
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
			show_message("Unknown argument : " & command_id) of MessageUtility
		end if
		
	end if
	
	restart_timer() of RefPanelController
	--call method "restartStopDisplayToggleTimer" of WindowVisibilityController
	return true
end open

on clicked theObject
	--log "start clicked"
	set a_tag to tag of theObject
	if a_tag is 7 then
		control_clicked(theObject) of PDFController
	else
		control_clicked(theObject)
	end if
end clicked

on control_clicked(theObject)
	set a_name to name of theObject
	if a_name is "Reload" then
		watchmi of RefPanelController with force_reloading
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
	set TerminalCommander to buildup() of (import_script("TerminalCommander"))
	tell TerminalCommander
		set_custom_title(call method "factoryDefaultForKey:" of appController with parameter "CustomTitle")
	end tell
	
	set RefPanelController to import_script("RefPanelController")
	set SheetManager to import_script("SheetManager")
	set AuxData to import_script("AuxData")
	set EditorClient to import_script("EditorClient")
	set ReplaceInput to import_script("ReplaceInput")
	
	--log "end of import library"
	show_startup_message("Loading Preferences ...")
	setup_constants()
	log "start of initializeing PDFController"
	load_settings() of PDFController
	
	log "end will finish launching"
end will finish launching

on awake from nib theObject
	--log "start awake from nib"
	set a_class to class of theObject
end awake from nib

on selected tab view item theObject tab view item tabViewItem
	log "start selected tab view item"
	selectedTab(tabViewItem) of SettingWindowController
end selected tab view item

on updated_selected_tab_view_item()
	log "start updated_selected_tab_view_item"
	SettingWindowController's updated_selected_tab_view_item()
end updated_selected_tab_view_item

on will quit theObject
	tell user defaults
		set contents of default entry "IsOpenedToolPalette" to is_opened() of ToolPaletteController
		set contents of default entry "IsOpenedRefPalette" to is_opened() of RefPanelController
	end tell
end will quit


on show_startup_message(a_msg)
	set contents of text field "StartupMessage" of window "Startup" to a_msg
end show_startup_message



