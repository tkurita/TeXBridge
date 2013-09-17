script TeXBridgeController
	property parent : class "NSObject"
	
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
	
	(*=== shared constants ===*)
	property _backslash : missing value
	property yenmark : character id 165
	property _com_delim : return
	
	property constantsDict : missing value
	
	property _my_signature : missing value
	
	(*=== dynamically loaded script objects ===*)
	property UtilityHandlers : missing value
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
	
	
	(* IB outlets *)
	property appController : missing value
	property startupMessageField : missing value
	property startupWindow : missing value
	
	(* class definition *)
	property NSString : class "NSString"
	property NSBundle : class "NSBundle"
	property NSDictionary : class "NSDictionary"
	property NSOpenPanel : class "NSOpenPanel"
	property NSUserDefaults : class "NSUserDefaults"
	property NSPasteboard : class "NSPasteboard"
	property LogWindowController : class "LogWindowController"
	property LogParser : class "LogParser"
	
	on import_script(a_name)
		--log "start import_script"
		set a_script to load script (path to resource a_name & ".scpt")
		return a_script
	end import_script
	
	(* events of application*)
	
	on do_replaceinput()
		ReplaceInput's do()
	end do_replaceinput
	
	on open theObject
		--log "start open"
		appController's stopTimer()
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
						UtilityHandlers's show_error(errno, "open", msg)
					else
						error msg number errno
					end if
				end try
				appController's showStatusMessage_("")
			else if command_class is "editSupport" then
				theObject's commandScript's do(EditCommands)
			else
				UtilityHandlers's show_message("Unknown commandClass : " & command_class)
			end if
		else
			set command_id to item 1 of theObject
			if command_id starts with "." then
				openOutputHadler(command_id) of CompileCenter
			else if (command_id as Unicode text) ends with ".dvi" then
				set a_xfile to XFile's make_with(command_id)
				tell NSUserDefaults's standardUserDefaults()
					set a_mode to integerForKey_("DVIPreviewMode") as integer
				end tell
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
				UtilityHandlers's show_message("Unknown argument : " & command_id)
			end if
			
		end if
		appController's restartTimer()
		return true
	end open
	
	on performTask_(a_script)
		appController's stopTimer()
		set a_script to a_script as script
		set a_result to a_script's do(me)
		appController's showStatusMessage_("")
		appController's restartTimer()
		try
			get a_result
		on error
			set a_result to missing value
		end try
		return a_result
	end performTask_
	
	on changePDFPreviewer_(sender)
		PDFController's changePDFPreviewer(sender)
	end changePDFPreviewer_
	
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
				startupWindow's orderOut_(missing value)
				UtilityHandlers's show_message(msg)
				return false
			end if
		end considering
		return true
	end check_mi_version
	
	on setup_constants()
		tell NSBundle's mainBundle()
			set my _my_signature to objectForInfoDictionaryKey_("CFBundleSignature") as text
			set plist_path to pathForResource_ofType_("ToolSupport", "plist") as text
		end tell
		tell NSDictionary's dictionaryWithContentsOfFile_(plist_path)
			set my _backslash to objectForKey_("backslash") as text
		end tell
		
		return true
	end setup_constants
	
	
	on setup()
		startupMessageField's setStringValue_("Loading Scripts ...")
		set UtilityHandlers to import_script("UtilityHandlers")
		set LogFileParser to import_script("LogFileParser")
		set EditCommands to import_script("EditCommands")
		set PDFController to import_script("PDFController")
		set CompileCenter to import_script("CompileCenter")
		set TeXDocController to import_script("TeXDocController")
		set DVIController to import_script("DVIController")
		set TerminalCommander to buildup() of (import_script("TerminalCommander"))
		tell TerminalCommander
			set_custom_title(appController's factoryDefaultForKey_("CustomTitle") as text)
		end tell
		
		set EditorClient to import_script("EditorClient")
		set ReplaceInput to import_script("ReplaceInput")
		
		--log "end of import library"
		startupMessageField's setStringValue_("Checking mi version ...")
		if not check_mi_version() then -- TODO
			quit
		end if
		startupMessageField's setStringValue_("Loading Preferences ...")
		setup_constants()
		--log "start of initializeing PDFController"
		PDFController's load_settings()
	end setup
	
	on performHandler_(a_name)
		set x_handler to XHandler's make_with(a_name as text, 0)
		try
			set a_result to x_handler's do(CompileCenter)
		on error msg number errno
			if errno is in {1700, 1710, 1720} then -- errors related to access com.apple.Terminal 
				UtilityHandlers's show_error(errno, "open", msg)
			else
				error msg number errno
			end if
		end try
		appController's showStatusMessage_("")
		try
			get a_result
		on error
			set a_result to missing value
		end try
		return a_result
	end performHandler_
	
	on show_setting_window()
		appController's showSettingWindow_(missing value)
	end show_setting_window
	
	on toggle_visibility_RefPalette()
		appController's toggleRefPalette()
	end toggle_visibility_RefPalette
	
	on open_RefPalette()
		appController's showRefPalette_(missing value)
	end open_RefPalette
	
	on toggle_visibility_ToolPalette()
		appController's toggleToolPalette()
	end toggle_visibility_ToolPalette
	
	on open_ToolPalette()
		appController's showToolPalette_(missing value)
	end open_ToolPalette
	
end script
