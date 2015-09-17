global XText
global UtilityHandlers
global TerminalCommander
global PDFController
global PathConverter
global _my_signature
global _com_delim
global _backslash

global NSUserDefaults
global NSString
global NSRunningApplication

property _preDVIPreviewMode : missing value
-- 0: open in Finder, 1: Mxdvi, 2: xdvi, 3: PictPrinter
-- 4: Skim, 5: command line

script XdviDriver
	property parent : AppleScript
	on set_file_type(a_xfile)
		a_xfile's set_types(_my_signature, "JDVI")
	end set_file_type
	
	on open_dvi(a_dvi, should_activate)
		--log "start open_dvi in XdviDriver"
		set x11AppName to "X11"
		if not (is_running(x11AppName) of UtilityHandlers) then
			tell application x11AppName
				launch
			end tell
		end if
		set a_texdoc to a_dvi's texdoc()
		update_src_special_flag_from_file() of a_dvi
		set cd_command to "cd " & (quoted form of (a_dvi's cwd()'s posix_path()))
		set dvi_file_name to a_dvi's filename()
		tell NSUserDefaults's standardUserDefaults()
			set dvi_command to stringForKey_("dviViewCommand") as text
		end tell
		set dvi_command to XText's make_with(dvi_command)
		set target_term to TerminalCommander
		if (a_dvi's src_special()) then
			if (a_texdoc is not missing value) then
				if a_texdoc's has_parent() then
					set_base_path(a_texdoc's file_ref()'s posix_path()) of PathConverter
					set sourceFile to relative_path of PathConverter for (a_texdoc's target_file()'s posix_path())
				else
					set sourceFile to a_dvi's texdoc()'s fileName()
				end if
				set srcpos_option to "-sourceposition"
				set dvi_command to dvi_command's push(space & srcpos_option & space & (quoted form of ((a_texdoc's doc_position() as Unicode text) & space & sourceFile)))
				set target_term to a_dvi's texdoc()'s target_terminal()
			end if
			--set miclient_path to quoted form of ((main bundle's resource path) & "/miclient")
			--set dvi_command to dvi_command's replace("%editor", quoted form of (miclient_path & " -b %l '%f'"))
			set mi_path to POSIX path of (path to application id "net.mimikaki.mi")
			set dvi_command to dvi_command's replace("%editor", quoted form of ("open " & mi_path & " -n --args '%f' +%l"))
			set dvi_command to dvi_command's replace(" -unique", "")
			set all_command to cd_command & _com_delim & dvi_command's as_text() & space & quoted form of dvi_file_name & " &"
			do_command of target_term for all_command without activation
		else
			set need_command to true
			if (not dvi_command's include("-unique")) then
				--log "no source special"
				try
					set pid to do shell script "/usr/sbin/lsof -a -Fp -c xdvi -u $USER " & quoted form of (a_dvi's posix_path())
				on error msg number 1
					set pid to missing value
				end try
				--log pid
				if pid is not missing value then
					set pid to text 2 thru -1 of pid
					do shell script "kill -USR1" & space & pid --reread
					set need_command to false
				end if
			end if
			if need_command then
				if a_texdoc is not missing value then
					set target_term to a_dvi's texdoc()'s target_terminal()
				end if
				set dvi_command to dvi_command's replace("-editor %editor", "")
				set all_command to cd_command & _com_delim & dvi_command's posix_path() & space & quoted form of dvi_file_name & " &"
				do_command of target_term for all_command without activation
			end if
		end if
		--log "end open_dvi in XdviDriver"
	end open_dvi
end script

script SimpleDriver
	property parent : AppleScript
	on set_file_type(a_xfile)
		set info_rec to a_xfile's info()
		set a_creator to info_rec's file creator
		set a_type to info_rec's file type
		if a_creator is _my_signature then
			a_xfile's set_types(missing value, a_type)
		end if
	end set_file_type
	
	on open_dvi(a_dvi, should_activate)
		set an_alias to a_dvi's file_as_alias()
		if an_alias is not missing value then
			tell application "Finder"
				open an_alias
			end tell
			return
		else
			activate
			set a_msg to UtilityHandler's localized_string("DviFileIsNotFound", {a_dvi's filename()})
			display alert a_msg
		end if
	end open_dvi
end script

script BaseDriver
	property parent : AppleScript
    
    on find_app(sender)
        try
            set my _app_alias to (my _app_alias as POSIX file) as alias
        on error
            set my _app_alias to UtilityHandlers's find_app_with_ideintifier(my _app_identifier)
        end try
        
        if my _app_alias is missing value then
            set a_msg to localized string my _whareIsAppMesssage
            try
                set my _app_alias to choose application with prompt a_msg as alias
            on error number -128
                return false
            end try
        end if
        return true
    end find_app
    
end script

script PictPrinterDriver
	property parent : BaseDriver
    property _app_identifier : "PictPrinter.system"
    property _app_alias : missing value
    property _whareIsAppMesssage : "whereisPictPrinter"

	on set_file_type(a_dvi)
		a_dvi's set_types(_my_signature, "JDVI")
	end set_file_type
	
	on open_dvi(a_dvi, should_activate)
		-- log "start open_dvi of PictPrinterDriver"
		(* try
			set pictprinter_app to path to application (get "PictPrinter") as alias
		on error
			set msg to localized string "pictPrinterIsNotFound"
			error msg number 1260
		end try
         *)
		a_dvi's update_src_special_flag_from_file()
		-- log "success update_src_special_flag_from_file"
		set a_texdoc to a_dvi's texdoc()
		set target_dvi_path to a_dvi's posix_path()
		set target_dvi_file to target_dvi_path as POSIX file
		if a_dvi's src_special() and (a_texdoc is not missing value) then
			--log "open dvi with forward search"
			if a_texdoc's has_parent() then
				--log "has parent"
				using terms from application "PictPrinter"
					tell application (my _app_alias as text)
						open target_dvi_file
						set dvis_list to DVIsList
					end tell
				end using terms from
				set subpath_list to missing value
				repeat with a_sublist in dvis_list
					set a_dvi_path to POSIX path of item 1 of a_sublist
					if a_dvi_path is target_dvi_path then
						if length of a_sublist > 1 then
							set subpath_list to items 2 thru -1 of a_sublist
						end if
						exit repeat
					end if
				end repeat
				set a_pathconv to PathConverter's make_with(a_texdoc's file_ref()'s posix_path())
				set a_source_path to a_texdoc's target_file()'s posix_path()
				if subpath_list is not missing value then
					repeat with a_subpath in subpath_list
						if a_subpath starts with "/" then
							set a_path to a_subpath
						else
							set a_path to absolute_path of a_pathconv for a_subpath
						end if
						if a_path is a_source_path then
							using terms from application "PictPrinter"
								tell application (my _app_alias as text)
									FindRoughly in dvi target_dvi_path startLine (a_texdoc's doc_position()) with source a_subpath
								end tell
							end using terms from
							exit repeat
						end if
					end repeat
				end if
			else
				set source_file to a_dvi's texdoc()'s filename()
				using terms from application "PictPrinter"
					tell application (my _app_alias as text)
						FindRoughly in dvi target_dvi_path startLine (a_texdoc's doc_position()) with source source_file
					end tell
				end using terms from
			end if
		else
			--log "open dvi without forward search"
			using terms from application "PictPrinter"
				tell application (my _app_alias as text)
					open target_dvi_file
				end tell
			end using terms from
		end if
		if should_activate then
            NSRunningApplication's activateAppOfIdentifier_(my _app_identifier)
		end if
		-- log "end open_dvi"
	end open_dvi
end script

script CLIDriver
    property parent : AppleScript
    on set_file_type(a_dvi)
		a_dvi's set_types(_my_signature, "JDVI")
	end set_file_type
    
    on open_dvi(a_dvi, should_activate)
        tell NSUserDefaults's standardUserDefaults()
            set command_template to stringForKey_("DVIPreviewCommand") as text
        end tell
		set a_dvipath to a_dvi's posix_path()'s quoted form
        set a_texdoc to a_dvi's texdoc()
        set a_texpath to a_texdoc's target_file()'s posix_path()'s quoted form
        set linenum to a_texdoc's doc_position()
        set x_text to XText's make_with(command_template)'s replace("%line", (linenum as text))
        set x_text to x_text's replace("%dvifile", a_dvipath)
        set x_text to x_text's replace("%texfile", a_texpath)
        do shell script "$SHELL -lc " & x_text's as_text()'s quoted form
	end open_dvi
end script

script SkimDriver
    property parent : BaseDriver
    property _app_identifier : "net.sourceforge.skim-app.skim"
    property _app_alias : missing value
    property _whareIsAppMesssage : "whereisSkim"
    
    on set_file_type(a_dvi)
		a_dvi's set_types("SKim", "JDVI")
	end set_file_type
    
    on open_dvi(a_dvi, should_activate)
        set my _app_alias to UtilityHandlers's find_app_with_ideintifier("net.sourceforge.skim-app.skim")
        set displayline to (POSIX path of my _app_alias)&"Contents/SharedSupport/displayline" -- %line %dvifile %texfile
        set a_dvipath to a_dvi's posix_path()'s quoted form
        set a_texdoc to a_dvi's texdoc()
        set a_texpath to a_texdoc's target_file()'s posix_path()'s quoted form
        set linenum to a_texdoc's doc_position() as text
        set a_command to displayline & space & linenum & space & a_dvipath & space & a_texpath
        do shell script a_command
	end open_dvi
end script
    
on file_ref()
	return my _dvifile
end file_ref

on filename()
	if my _dvifile is not missing value then
		return my _dvifile's item_name()
	end if
	return my _texdoc's name_for_suffix("dvi")
end filename

on texdoc()
	return my _texdoc
end texdoc

on cwd()
	if my _texdoc is not missing value then
		return my _texdoc's cwd()
	end if
	
	return my _dvifile's parent_folder()
end cwd

on posix_path()
	return my _dvifile's posix_path()
end posix_path

on file_as_alias()
	if my _dvifile is missing value then
		set an_alias to my _texdoc's tex_file()'s change_path_extension("dvi")'s as_alias()
	else
		set an_alias to my _dvifile's as_alias()
	end if
end file_as_alias

on set_src_special(a_flag)
	set my _isSrcSpecial to a_flag
end set_src_special

on src_special()
	return my _isSrcSpecial
end src_special

on set_file_type()
	set_file_type(my _dvifile) of my _dvi_driver
end set_file_type

on set_dvi_driver(a_mode)
	if a_mode is 0 then
		set my _dvi_driver to SimpleDriver
	else if a_mode is 2 then
		set my _dvi_driver to XdviDriver
	else if a_mode is 3 then
		set my _dvi_driver to PictPrinterDriver
    else if a_mode is 4 then
        set my _dvi_driver to SkimDriver
    else if a_mode is 5 then
        set my _dvi_driver to CLIDriver
	else
		--log "DVI Preview setting is invalid."
		error "DVI Preview setting is invalid." number 1290
	end if
end set_dvi_driver

on getModDate()
	return modification date of (my _dvifile's info())
end getModDate

on remove_src_special_flag_in_comment()
	set a_file to my _dvifile's as_alias()
	tell application "Finder"
		set a_comment to comment of a_file
	end tell
	if a_comment is "Source Specials" then
		ignoring application responses
			tell application "Finder"
				set comment of a_file to ""
			end tell
		end ignoring
	end if
end remove_src_special_flag_in_comment

on set_src_special_flag()
	set a_path to my _dvifile's posix_path()
	tell NSString's stringWithString_(a_path)
		setHasSourceSpecials_((my _texdoc's typeset_command()) contains "-src")
	end tell
end set_src_special_flag

on update_src_special_flag_from_file()
	--log "start update_src_special_flag_from_file"
	if src_special() is missing value then
		set a_path to my _dvifile's posix_path()
		tell NSString's stringWithString_(a_path)
			set a_flag to hasSourceSpecials() as integer
		end tell
		if a_flag is -1 then
			tell application "Finder"
				set a_comment to comment of (my _dvifile's as_alias())
			end tell
			set src_flag to a_comment is "Source Specials"
			if src_flag then
				ignoring application responses
					tell application "Finder"
						set comment of my _dvifile's as_alias() to ""
					end tell
				end ignoring
			end if
			tell NSString's stringWithString_(a_path)
				setHasSourceSpecials_(src_flag)
			end tell
			set_src_special(src_flag)
		else if a_flag is 1 then
			set_src_special(true)
		else if a_flag is 0 then
			set_src_special(false)
		end if
	end if
	--log "end update_src_special_flag_from_file"
end update_src_special_flag_from_file

on open_dvi given activation:should_activate -- deprecated use_perform_preview
	-- log "start open_dvi of DVIController"
    my _dvi_driver's open_dvi(me, should_activate)
end open_dvi

on perform_preview({should_activate:a_flag})
    my _dvi_driver's open_dvi(me, a_flag)
end perform_preview

on dvi_to_pdf()
	--log "start dvi_to_pdf"
	set a_pdf to lookup_pdf_file()
	--log "success lookup_pdf_file"
	--check busy status of pdf file.
	if a_pdf is not missing value then
		if not prepare_dvi_to_pdf() of a_pdf then
			return missing value
		end if
	end if
	
	--log "convert a DVI file into a PDF file"
	set a_command to my _texdoc's dvipdf_command()
	set cd_command to "cd" & space & (quoted form of (cwd()'s posix_path()))
	set targetFileName to my _texdoc's name_for_suffix("dvi")
	set all_command to cd_command & _com_delim & a_command & space & "'" & targetFileName & "'"
	
	--send_command of TerminalCommander for all_command
	set a_term to texdoc()'s target_terminal()
	do_command of (a_term) for all_command without activation
	--copy TerminalCommander to a_term
	a_term's wait_termination(300)
	
	if a_pdf is missing value then
		set a_pdf to lookup_pdf_file()
	end if
	
	--log "end of dvi_to_pdf"
	return a_pdf
end dvi_to_pdf

on lookup_pdf_file()
	--log "start lookup_pdf_file"
	return PDFController's make_with(me)'s lookup_file()
end lookup_pdf_file

on lookup_file()
	--log "start lookup_file in DVIController"
	set a_dvifile to texdoc()'s tex_file()'s change_path_extension("dvi")
	if a_dvifile's item_exists() then
		set_dvifile(a_dvifile)
		set_file_type()
		return me
	end if
    return missing value
end lookup_dvi

on set_dvifile(a_xfile)
	set my _dvifile to a_xfile
end set_dvifile

on set_log_parser(a_log_parser)
	set my _log_parser to a_log_parser
end set_log_parser

on log_parser()
	return my _log_parser
end log_parser

on make
	tell NSUserDefaults's standardUserDefaults()
		set a_mode to integerForKey_("DVIPreviewMode") as integer
	end tell
	return make_with_mode(a_mode)
end make

on make_with_mode(a_mode)
	script DVIController
		property _texdoc : missing value
		property _dvifile : missing value
		property _isSrcSpecial : missing value
		property _log_parser : missing value
		property _dvi_driver : SimpleDriver
	end script
	
	DVIController's set_dvi_driver(a_mode)
	return DVIController
end make_with_mode

on make_with(a_texdoc)
	set a_dvi to make
	set a_dvi's _texdoc to a_texdoc
	return a_dvi
end make_with

on make_with_xfile(a_dvifile)
	set a_dvi to make
	set a_dvi's _dvifile to a_dvifile
	return a_dvi
end make_with_xfile

on make_with_xfile_mode(a_dvifile, a_mode)
	set a_dvi to make_with_mode(a_mode)
	set a_dvi's _dvifile to a_dvifile
	return a_dvi
end make_with_xfile_mode

on check_app(mode_idx)
    set a_driver to item (mode_idx+1) of ¬
    {missing value, missing value, missing value, PictPrinterDriver, SkimDriver, missing value}
    if a_driver is missing value then
        return true
    end if
    
    return a_driver's find_app(me)
end check_pdf_app

on changeDVIPreviewer(sender)
    set user_defaults to NSUserDefaults's standardUserDefaults()
    set a_mode to user_defaults's integerForKey_("DVIPreviewMode") as integer
    
    if not check_app(a_mode) then
        user_defaults's setInteger_forKey_(my _preDVIPreviewMode, "DVIPreviewMode")
        UtilityHandlers's show_localized_essage("DVIPreviewIsInvalid")
        return
    end if

    set my _preDVIPreviewMode to user_defaults's integerForKey_("DVIPreviewMode") as integer
end changeDVIPreviewer

on load_settings()
    --log "start load_settings of DVIController"
    set user_defaults to NSUserDefaults's standardUserDefaults()
    set my _preDVIPreviewMode to user_defaults's integerForKey_("DVIPreviewMode") as integer
	if not check_app(my _preDVIPreviewMode) then
        appController's revertToFactoryDefaultForKey_("DVIPreviewMode")
        set my _preDVIPreviewMode to user_defaults's integerForKey_("DVIPreviewMode") as integer
    end if
    --log "end load_settings of DVIController"
end load_settings

on is_dvi()
    return true
end is_dvi
