property NSBundle : class "NSBundle"
property NSDictionary : class "NSDictionary"

script TeXBridgeController
	property parent : class "NSObject"
	
	property PathConverter : "@module"
	property XDict : "@module"
	property XFile : "@module"
	property XList : "@module"
	property XText : "@module"
	property PathInfo : "@module"
	property TerminalCommanderBase : "@module TerminalCommander"
    property _local_only_ : true
    property _ : application (get "TeXToolsLib")'s loader()'s setup(me)
	
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
    
	on import_script(a_name)
		--log "start import_script"
		set a_script to load script (path to resource a_name & ".scpt")
		return a_script
	end import_script
	
	on import_script_subfolder(a_name)
		set a_script to load script (path to resource a_name & ".scpt" in directory "Scripts")
		return a_script
	end import_script_subfolder
	
	(* events of application*)
	
	on do_replaceinput()
		ReplaceInput's do()
	end do_replaceinput
	
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
	
    on changeDVIPreviewer_(sender)
		DVIController's changeDVIPreviewer(sender)
	end changeDVIPreviewer_
    
	on changePDFPreviewer_(sender)
		PDFController's changePDFPreviewer(sender)
	end changePDFPreviewer_
	
	on check_mi_version()
		-- log "start check_mi_version"
        try
            set app_file to EditorClient's application_file()
            set a_ver to version of application (app_file as text)
        on error errmsg number errno
            UtilityHandlers's show_error(errno, "check_mi_version", errmsg)
            return false
        end try
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
        -- log "end check_mi_version"
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
		-- log "start setup"
		startupMessageField's setStringValue_("Loading Scripts ...")
		set UtilityHandlers to import_script("UtilityHandlers")
		set LogFileParser to import_script("LogFileParser")
		set EditCommands to import_script("EditCommands")
		set PDFController to import_script_subfolder("PDFController")
		set CompileCenter to import_script("CompileCenter")
		set TeXDocController to import_script("TeXDocController")
		set DVIController to import_script("DVIController")
		set TerminalCommander to buildup() of (import_script("TerminalCommander"))
		
		set EditorClient to import_script("EditorClient")
		set ReplaceInput to import_script("ReplaceInput")
		
		-- log "end of import library"
		startupMessageField's setStringValue_("Checking mi version ...")

		if not check_mi_version() then
			quit
			return false
		end if
        
		startupMessageField's setStringValue_("Loading Preferences ...")
		setup_constants()
        DVIController's load_settings()
        PDFController's load_settings()
        -- log "end of setup"
	end setup
	
    (* Tool bar actions *)

    on perform_action(action)
        try
            set a_result to run action
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
    end

    on typesetPDFPreview()
        script action
            CompileCenter's typeset_preview_pdf()
        end
        perform_action(action)
    end

    on dviToPDF()
        script action
            CompileCenter's dvi_to_pdf()
        end
        perform_action(action)
    end

    on dviPreview()
        script action
            CompileCenter's preview_dvi()
        end script
        perform_action(action)
    end
    
    on quickTypesetPreview()
        script action
            CompileCenter's quick_typeset_preview()
        end script
        perform_action(action)
    end
	
    (* tool commands *)
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
