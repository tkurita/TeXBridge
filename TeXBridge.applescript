property PathConverter : module
property XDict : module
property XFile : module
property XList : module
property XText : module
property XHandler : module
property FrontAccess : module
property PathInfo : module
property TerminalCommanderBase : module "TerminalCommander"
property _ : boot ((module loader of application (get "TeXToolsLib"))'s collecting_modules(false)) for me

property appController : missing value

(*=== shared constants ===*)
property _backslash : missing value
property yenmark : character id 165
property _com_delim : return

property constantsDict : missing value

property _my_signature : missing value

(*=== dynamically loaded script objects ===*)
property UtilityHandlers : missing value
property MessageUtility : missing value
property DefaultsManager : missing value
property ToolPaletteController : missing value
property LogFileParser : missing value
property ReplaceInput : missing value
property EditCommands : missing value
property TerminalCommander : missing value
property CompileCenter : missing value
property PDFController : missing value
property TeXDocController : missing value
property DVIController : missing value
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
	--log "start lanunched"
	--log "will show refpalette"
	--hide window "Startup"
	
	(*debug code*)
	(*open window*)
	--show_setting_window()
	
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
	call method "stopTimer" of appController
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
			call method "showStatusMessage:" of appController with parameter ""
			
		else if command_class is "editSupport" then
			theObject's commandScript's do(EditCommands)
		else
			show_message("Unknown commandClass : " & command_class) of MessageUtility
		end if
	else
		set command_id to item 1 of theObject
		if command_id starts with "." then
			openOutputHadler(command_id) of CompileCenter
		else if (command_id as Unicode text) ends with ".dvi" then
			set a_xfile to XFile's make_with(command_id)
			set a_mode to contents of default entry "DVIPreviewMode" of user defaults
			if a_mode is 0 then
				set def_app to a_xfile's info()'s default application
				if def_app is (path to me) then
					activate
					set a_result to choose from list {"xdvi", "PictPrinter"} with prompt "Choose a DVI Previewer :"
					if class of a_result is not list then
						set a_mode to -1
					else
						set a_result to item 1 of a_result
						if a_result is "xdvi" then
							set a_mode to 2
						else
							set a_mode to 3
						end if
					end if
				end if
			end if
			if a_mode is not -1 then
				set a_dvi to DVIController's make_with_xfile_mode(a_xfile, a_mode)
				open_dvi of a_dvi with activation
			end if
		else
			show_message("Unknown argument : " & command_id) of MessageUtility
		end if
		
	end if
	
	call method "restartTimer" of appController
	return true
end open

on clicked theObject
	--log "start clicked"
	set a_tag to tag of theObject
	if a_tag is 7 then
		control_clicked(theObject) of PDFController
	end if
end clicked

on check_mi_version()
	-- log "start check_mi_version"
	set app_file to EditorClient's application_file()
	tell application "System Events"
		set a_ver to version of app_file
	end tell
	if (count word of a_ver) > 1 then
		-- before 2.1.11r1 , the version number was "mi version x.x.x". 
		-- obtain "x.x.x" from "mi version x.x.x"
		set a_ver to last word of a_ver
	end if
	considering numeric strings
		if a_ver is not greater than or equal to "2.1.11" then
			set msg to UtilityHandlers's localized_string("mi $1 is not supported.", {a_ver})
			hide window "Startup"
			MessageUtility's show_message(msg)
			return false
		end if
	end considering
	return true
end check_mi_version

on setup_constants()
	tell main bundle
		set plistPath to path for resource "ToolSupport" extension "plist"
	end tell
	set constantsDict to call method "dictionaryWithContentsOfFile:" of class "NSDictionary" with parameter plistPath
	set _backslash to backslash of constantsDict
	
	set my _my_signature to call method "objectForInfoDictionaryKey:" of main bundle with parameter "CFBundleSignature"
	return true
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
	set TerminalCommander to buildup() of (import_script("TerminalCommander"))
	tell TerminalCommander
		set_custom_title(call method "factoryDefaultForKey:" of appController with parameter "CustomTitle")
	end tell
	
	set EditorClient to import_script("EditorClient")
	set ReplaceInput to import_script("ReplaceInput")
	
	--log "end of import library"
	show_startup_message("Checking mi version ...")
	if not check_mi_version() then
		quit
	end if
	show_startup_message("Loading Preferences ...")
	setup_constants()
	--log "start of initializeing PDFController"
	load_settings() of PDFController
	
	--log "end will finish launching"
end will finish launching

on perform_handler(a_name)
	set x_handler to XHandler's make_with(a_name, 0)
	try
		x_handler's do(CompileCenter)
	on error msg number errno
		if errno is in {1700, 1710, 1720} then -- errors related to access com.apple.Terminal 
			MessageUtility's show_error(errno, "open", msg)
		else
			error msg number errno
		end if
	end try
	call method "showStatusMessage:" of appController with parameter ""
end perform_handler

on show_startup_message(a_msg)
	--set contents of text field "StartupMessage" of window "Startup" to a_msg
	call method "setStartupMessage:" of appController with parameter a_msg
end show_startup_message

-- if moved ASObjC, call directry appController's methods
on show_setting_window()
	call method "showSettingWindow:" of appController with parameter missing value
end show_setting_window

on toggle_visibility_RefPalette()
	call method "toggleRefPalette" of appController
end toggle_visibility_RefPalette

on open_RefPalette()
	call method "showRefPalette:" of appController with parameter missing value
end open_RefPalette

on toggle_visibility_ToolPalette()
	call method "toggleToolPalette" of appController
end toggle_visibility_ToolPalette

on open_ToolPalette()
	call method "showToolPalette:" of appController with parameter missing value
end open_ToolPalette
