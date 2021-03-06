global UtilityHandlers
global appController
global XText

property NSUserDefaults : class "NSUserDefaults"
property NSRunningApplication : class "NSRunningApplication"

property _prePDFPreviewMode : 1
-- 0: open in Finder, 1: Preview.app, 2: Adobe Reader, 3: Acrobat
-- 4: Skim, 5: command line

on integer_from_user_defaults(a_key)
	tell NSUserDefaults's standardUserDefaults()
		return integerForKey_(a_key) as integer
	end tell
end integer_from_user_defaults

on changePDFPreviewer(sender)
	--log "start changePDFPreviewer"
	set new_mode to integer_from_user_defaults("PDFPreviewMode")
    if not check_app(new_mode) then
        tell NSUserDefaults's standardUserDefaults()
            setInteger_forKey_(my _prePDFPreviewMode, "PDFPreviewMode")
        end tell
        UtilityHandlers's show_localized_essage("PDFPreviewIsInvalid")
        return
    end if
	--log "end changePDFPreviewer"
	set my _prePDFPreviewMode to integer_from_user_defaults("PDFPreviewMode")
end changePDFPreviewer

on append_aux_record(a_record)
    set my _aux_record to a_record & my _aux_record
    return me
end append_aux_record

on aux_record()
    return my _aux_record
end aux_record

on file_hfs_path()
	return my _pdffile's hfs_path()
end file_hfs_path

on file_info()
	return my _pdffile's re_info()
end file_info

on file_as_alias()
	return my _pdffile's as_alias()
end file_as_alias

on file_ref()
	return my _pdffile
end file_ref

on filename()
	return my _pdffile's item_name()
end filename

on posix_path()
	return my _pdffile's posix_path()
end posix_path

on setup_pdfdriver()
	--log "start setup_pdfdriver()"
	set PDFPreviewMode to integer_from_user_defaults("PDFPreviewMode")
	if PDFPreviewMode is 0 then
		set my _pdfdriver to my AutoDriver
	else if PDFPreviewMode is 1 then
		set my _pdfdriver to my ReloadablePreviewDriver
	else if PDFPreviewMode is 2 then
		set my _pdfdriver to my AdobeReaderDriver
    else if PDFPreviewMode is 3 then
		set my _pdfdriver to my AcrobatDriver
    else if PDFPreviewMode is 4 then
        set my _pdfdriver to my SkimDriver
    else if PDFPreviewMode is 5 then
        set my _pdfdriver to my CLIDriver
	else
		error "PDF Preview Setting is invalid." number 1280
	end if
	--log "end of setup_pdfdriver()"
end setup_pdfdriver

on lookup_file()
    set my _pdffile to my _dvi's file_ref()'s change_path_extension("pdf")
    if my _pdffile's item_exists() then
        return me
    end if
    return missing value
end setup

on set_pdffile(x_file)
    set my _pdffile to x_file
end set_pdffile

on file_exists()
	return my _pdffile's item_exists()
end file_exists

on prepare_dvi_to_pdf()
	return prepare(a reference to me) of my _pdfdriver
end prepare_dvi_to_pdf

on open_pdf()
	--log "start open_pdf"
	open_pdf(a reference to me) of my _pdfdriver
	--log "end open_pdf"
end open_pdf

on perform_preview(opts)
    my _pdfdriver's open_pdf(me)
end perform_preview

on texdoc()
    return my _dvi's texdoc()
end texdoc

on log_parser()
    return my _log_parser
end log_parser

on set_log_parser(a_log_parser)
    set my _log_parser to a_log_parser
    return me
end set_log_parser

on make_with(a_dvi)
	script PDFController
		property _dvi : a_dvi
		property _pdffile : missing value
		property _pdfdriver : my AutoDriver
        property _log_parser : missing value
        property _aux_record : {}
	end script
	
	PDFController's setup_pdfdriver()
	return PDFController
end make_with

script SimpleDriver -- not used
    property parent : AppleScript
    
	on prepare(a_pdf)
		set an_info to a_pdf's file_info()
		set is_file_busy to busy status of an_info
		if is_file_busy then
			try
				tell application (default application of an_info as Unicode text)
					close window name of an_info
				end tell
				set is_file_busy to busy status of (a_pdf's file_info())
			end try
			
			if is_file_busy then
				set a_msg to UtilityHandlers's localized_string("FileIsOpened", {a_pdf's file_hfs_path()})
				EditorClient's show_message(a_msg)
				return false
			else
				return true
			end if
		else
			return true
		end if
	end prepare
	
	on open_pdf(a_pdf)
		try
			tell application "Finder"
				open a_pdf's file_as_alias()
			end tell
		on error msg number errno
			activate
			display dialog msg buttons {"OK"} default button "OK"
		end try
	end open_pdf
end script

script GenericDriver
    property parent : AppleScript
    property _app_identifier : missing value
    property _app_alias : missing value
    property _whareIsAppMesssage : ""
    
    property _window_count : missing value
    property _process_name : missing value
    
    on set_app_identifier(app_id)
        set my _app_identifier to app_id
    end set_app_identifier

    on find_app(sender)
        -- log ("start find_app for " & my _app_identifier)
        try
            set my _app_alias to (my _app_alias as POSIX file) as alias
        on error
            set my _app_alias to UtilityHandlers's find_app_with_ideintifier(my _app_identifier)
        end try
        
        if my _app_alias is missing value then
            set a_msg to localized string my _whareIsAppMesssage
            set my _app_alias to choose application with prompt a_msg as alias
        end if
    end find_app
    
	on prepare(a_pdf)
        if application id (my _app_identifier) is running then
			tell application "System Events"
				tell first item of application processes of (my _app_identifier)
					set my _window_count to count windows
                    set my _process_name to name of it
				end tell
			end tell
		end if
		return true
	end prepare
	
	on open_pdf(a_pdf)
		tell application id (my _app_identifier)
			open a_pdf's file_as_alias()
		end tell
		
		if my _window_count is not missing value then
			tell application "System Events"
				tell application process (my _process_name)
					set current_win_counts to count windows
				end tell
			end tell
			
            NSRunningApplication's activateAppOfIdentifier_(my _app_identifier)
			
			if my _window_count is current_win_counts then
				tell application "System Events"
					tell application process (my _process_name)
						set closeButton to buttons of window 1 whose subrole is "AXCloseButton"
						perform action "AXPress" of item 1 of closeButton
					end tell
				end tell
				delay 1
				tell application id (my _app_identifier)
					open a_pdf's file_as_alias()
				end tell
			end if
            else
			activate application id (my _app_identifier)
		end if
	end open_pdf
end script

script AdobeReaderDriver
    property parent : GenericDriver
    property _app_identifier : "com.adobe.Reader"
    property _app_alias : missing value
    property _whareIsAppMesssage : "whereisAdobeAcrobat"
end script

script AcrobatDriver
    property parent : GenericDriver
    property _is_app_running : false
    property _app_identifier : "com.adobe.Acrobat.Pro"
    property _process_name : missing value
    property _app_alias  : missing value
    property _whareIsAppMesssage : "whereisAdobeAcrobat"
    
	on prepare(a_pdf)
		--log "start prepare of AcrobatDriver"
        set my _is_app_running to false
        
        if application id _app_identifier is running then
            tell application "System Events"
                tell first application processes whose bundle identifier is my _app_identifier
                    set my _process_name to name of it
                    set visible of it to true
                end tell
            end tell
			close_pdf(a_pdf)
            set my _is_app_running to true
        end if
		--log "end prepare in AcrobatDriver"
		return true
	end prepare
	
    on set_page_number(a_pdf, pnum)
        a_pdf's append_aux_record({page_number:pnum})
    end set_page_number
    
    on page_number(a_pdf)
        try
            return a_pdf's aux_record()'s page_number
        on error number -1728
            return missing value
        end try
    end page_number
        
	on close_pdf(a_pdf)
		--log "start close_pdf of AcrobatDriver"
		set a_filename to a_pdf's filename()
		using terms from application "Adobe Acrobat Pro"
			tell application (_app_alias as text)
				if exists document a_filename then
					set a_path to file alias of document a_filename as Unicode text
					if a_path is (a_pdf's file_hfs_path()) then
						bring to front document a_filename
                        my set_page_number(a_pdf, page number of PDF Window 1 of active doc)
						try
							close active doc
						on error
							delay 1
							close active doc
						end try
					end if
				end if
			end tell
		end using terms from
		--log "end close_pdf of AcrobatDriver"
	end close_pdf
	
	on open_pdf(a_pdf)
		--log "start open_pdf in AcrobatDriver"
		using terms from application "Adobe Acrobat Pro"
			tell application (my _app_alias as text)
                if my _is_app_running then
                    launch
                end if
				open a_pdf's file_as_alias()
                set pnum to my page_number(a_pdf)
				if pnum is not missing value then
					set page number of PDF Window 1 of active doc to pnum
                end if
			end tell
		end using terms from
        NSRunningApplication's activateAppOfIdentifier_(my _app_identifier)
		--log "end open_pdf in AcrobatDriver"
	end open_pdf
end script

script ReloadablePreviewDriver
    property parent : AppleScript
    property _app_identifier : "com.apple.Preview"
    
	on prepare(a_pdf)
		return true
	end prepare
	
	on open_pdf(a_pdf)
		tell application id (my _app_identifier)
			open a_pdf's file_as_alias()
		end tell
        NSRunningApplication's activateAppOfIdentifier_(my _app_identifier)
	end open_pdf
end script

script SkimDriver
    property parent : GenericDriver
    property _app_identifier : "net.sourceforge.skim-app.skim"
    property _app_alias : missing value
    property _whareIsAppMesssage : "whereisSkim"
    
    on prepare(a_pdf)
        return true
    end prepare
    
    on open_pdf(a_pdf)
        --log "start open_pdf in SkimDriver"
        set a_pdfpath to a_pdf's posix_path()'s quoted form
        set a_texdoc to a_pdf's _dvi's texdoc()
        set linenum to a_texdoc's doc_position() as text
        if linenum is "" then
            set a_command to "open -a "&(quoted form of POSIX path of my _app_alias)& space & a_pdfpath
        else
            set displayline to (POSIX path of my _app_alias)&"Contents/SharedSupport/displayline"
            
            set a_texpath to a_texdoc's target_file()'s posix_path()'s quoted form
            set a_command to displayline &space &linenum &space &a_pdfpath &space &a_texpath
        end if
        
        do shell script a_command
        --log "end open_pdf in SkimDriver"
    end open_pdf
end script

script AutoDriver
    property parent : AppleScript
    
	on prepare(a_pdf)
        set app_info to info for (default application of (a_pdf's file_info()))
        set app_id to bundle identifier of app_info
        
        if ("com.adobe.Reader" is app_id) then
            set a_driver to AdobeReaderDriver
        else if ("com.adobe.Acrobat.Pro" is app_id) then
            set a_driver to AcrobatDriver
        else if ("com.apple.Preview" is app_id) then
            set a_driver to ReloadablePreviewDriver
        else if ("net.sourceforge.skim-app.skim" is app_id) then
            set a_driver to SkimDriver
        else
			set a_driver to GenericDriver
		end if
        a_pdf's append_aux_record({target_driver: a_driver})
        
		return a_driver's prepare(a_pdf)
	end prepare
	
    on resolve_target_driver(a_pdf)
        try
            return a_pdf's aux_record()'s target_driver
        on error number -1728
            return missing value
        end try
    end resolve_target_driver
    
	on open_pdf(a_pdf)
        set a_driver to resolve_target_driver(a_pdf)
        if a_driver is missing value then
            prepare(a_pdf)
            set a_driver to resolve_target_driver(a_pdf)
        end if
		a_driver's open_pdf(a_pdf)
	end open_pdf
end script

script CLIDriver
    property parent : AppleScript
    on prepare(a_pdf)
        return true
    end prepare
    
    on open_pdf(a_pdf)
        -- log "start open_pdf of CLIDriver"
        tell NSUserDefaults's standardUserDefaults()
            set command_template to stringForKey_("PDFPreviewCommand") as text
        end tell
        set a_pdfpath to a_pdf's posix_path()'s quoted form
        set a_texdoc to a_pdf's _dvi's texdoc()
        set a_texpath to a_texdoc's target_file()'s posix_path()'s quoted form
        set linenum to a_texdoc's doc_position()
        set x_text to XText's make_with(command_template)'s replace("%line", (linenum as text))
        set x_text to x_text's replace("%pdffile", a_pdfpath)
        set x_text to x_text's replace("%texfile", a_texpath)
        do shell script "$SHELL -lc " & x_text's as_text()'s quoted form
    end open_pdf
end script

on check_app(mode_idx)
    --log "start check_app in PDFController for index :" & (mode_idx as text)
    set a_driver to item (mode_idx+1) of {missing value, missing value, AdobeReaderDriver, AcrobatDriver, SkimDriver, missing value, missing value}
    if a_driver is missing value then
        return true
    end if
    
    try
        a_driver's find_app(me)
    on error msg number -128
        return false
    end try
    return true
end check_app

on load_settings()
    set my _prePDFPreviewMode to integer_from_user_defaults("PDFPreviewMode")
	if not check_app(my _prePDFPreviewMode) then
        appController's revertToFactoryDefaultForKey_("PDFPreviewMode")
        set my _prePDFPreviewMode to integer_from_user_defaults("PDFPreviewMode")
    end if
end load_settings

on is_dvi()
    return false
end is_dvi
