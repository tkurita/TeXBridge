global XText
global UtilityHandlers
global TerminalCommander
global PDFController
global PathConverter
global _my_signature
global _com_delim
global _backslash

script XdviDriver
	property parent : AppleScript
	on set_file_type(a_xfile)
		a_xfile's set_types(_my_signature, "JDVI")
	end set_file_type
	
	on open_dvi given sender:a_dvi, activation:aFlag
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
		set dvi_file_name to a_dvi's fileName()
		set dviViewCommand to contents of default entry "dviViewCommand" of user defaults
		if (a_dvi's src_special()) then
			if (a_texdoc is not missing value) then
				if a_texdoc's has_parent() then
					set_base_path(a_texdoc's file_ref()'s posix_path()) of PathConverter
					set sourceFile to relative_path of PathConverter for (a_texdoc's target_file()'s posix_path())
				else
					set sourceFile to a_dvi's texdoc()'s fileName()
				end if
				set srcpos_option to "-sourceposition"
				set dviViewCommand to dviViewCommand & space & srcpos_option & space & (quoted form of ((a_texdoc's doc_position() as Unicode text) & space & sourceFile))
			end if
			set miclient_path to quoted form of ((main bundle's resource path) & "/miclient")
			set dviViewCommand to replace of XText for dviViewCommand from "%editor" by (quoted form of (miclient_path & " -b %l '%f'"))
			set all_command to cd_command & _com_delim & dviViewCommand & space & quoted form of dvi_file_name & " &"
			do_command of TerminalCommander for all_command without activation
		else
			set need_command to true
			if (dviViewCommand does not contain "-unique") then
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
				set dviViewCommand to replace of XText for dviViewCommand from "-editor %editor" by ""
				set all_command to cd_command & _com_delim & dviViewCommand & space & quoted form of dvi_file_name & " &"
				do_command of TerminalCommander for all_command without activation
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
		set a_type to info_rec's file creator
		if a_creator is _my_signature then
			a_xfile's set_types(missing value, a_type)
		end if
	end set_file_type
	
	on open_dvi given sender:a_dvi, activation:aFlag
		set an_alias to a_dvi's file_as_alias()
		if an_alias is not missing value then
			tell application "Finder"
				open an_alias
			end tell
			return
		else
			activate
			set a_msg to UtilityHandler's localized_string("DviFileIsNotFound", {a_dvi's fileName()})
			display alert a_msg
		end if
	end open_dvi
end script

script MxdviDriver
	property parent : AppleScript
	on set_file_type(a_dvi)
		a_dvi's set_types("Mxdv", "JDVI")
	end set_file_type
	
	on open_dvi given sender:a_dvi, activation:aFlag
		--log "start open_dvi of MxdviDriver"
		try
			set mxdviApp to path to application (get "Mxdvi") as alias
		on error
			set msg to localized string "mxdviIsnotFound"
			error msg number 1260
		end try
		update_src_special_flag_from_file() of a_dvi
		--log "success update_src_special_flag_from_file"
		set a_texdoc to a_dvi's texdoc()
		if a_dvi's src_special() and (a_texdoc is not missing value) then
			set mxdviPath to quoted form of POSIX path of ((mxdviApp as Unicode text) & "Contents:MacOS:Mxdvi")
			set targetDviPath to quoted form of (a_dvi's posix_path())
			set all_command to mxdviPath & "  -sourceposition " & (a_texdoc's doc_position()) & space & targetDviPath & " &"
			--log all_command
			if a_texdoc's is_use_term() then
				do_command of TerminalCommander for all_command without activation
			else
				do shell script all_command
			end if
		else
			tell application (mxdviApp as Unicode text)
				if aFlag then activate
				open a_dvi's file_as_alias()
			end tell
		end if
		--log "end open_dvi"
	end open_dvi
end script

script PictPrinterDriver
	property parent : AppleScript
	on set_file_type(a_dvi)
		a_dvi's set_types(_my_signature, "JDVI")
	end set_file_type
	
	on open_dvi given sender:a_dvi, activation:aFlag
		--log "start open_dvi of MxdviDriver"
		try
			set pictprinter_app to path to application (get "PictPrinter") as alias
		on error
			set msg to localized string "pictPrinterIsnotFound"
			error msg number 1260
		end try
		a_dvi's update_src_special_flag_from_file()
		--log "success update_src_special_flag_from_file"
		set a_texdoc to a_dvi's texdoc()
		set targetDviPath to a_dvi's posix_path()
		if a_dvi's src_special() and (a_texdoc is not missing value) then
			using terms from application "PictPrinter"
				tell application (pictprinter_app as Unicode text)
					FindRoughly in dvi targetDviPath startLine (a_texdoc's doc_position())
				end tell
			end using terms from
		else
			using terms from application "PictPrinter"
				tell application (pictprinter_app as Unicode text)
					FindRoughly in dvi targetDviPath
				end tell
			end using terms from
			(*
			tell application (pictprinter_app as Unicode text)
				open a_dvi's file_as_alias()
			end tell
			*)
		end if
		if aFlag then call method "activateAppOfType:" of class "SmartActivate" with parameter "pPrn"
		--log "end open_dvi"
	end open_dvi
end script

on file_ref()
	return my _dvifile
end file_ref

on fileName()
	if my _dvifile is not missing value then
		return my _dvifile's item_name()
	end if
	return my _texdoc's name_for_suffix("dvi")
end fileName

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

on set_dvi_driver()
	--log "start set_dvi_driver"
	set DVIPreviewMode to contents of default entry "DVIPreviewMode" of user defaults
	--log "after get DVIPreviewMode"
	if DVIPreviewMode is 0 then
		set my _dvi_driver to SimpleDriver
	else if DVIPreviewMode is 1 then
		set my _dvi_driver to MxdviDriver
	else if DVIPreviewMode is 2 then
		set my _dvi_driver to XdviDriver
	else if DVIPreviewMode is 3 then
		set my _dvi_driver to PictPrinterDriver
	else
		--log "DVI Preview setting is invalid."
		error "DVI Preview setting is invalid." number 1290
	end if
	--log "end set_dvi_driver"
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
	call method "setHasSourceSpecials:" of a_path with parameter ((my _texdoc's typeset_command()) contains "-src")
end set_src_special_flag

on update_src_special_flag_from_file()
	--log "start update_src_special_flag_from_file"
	if src_special() is missing value then
		set a_path to my _dvifile's posix_path()
		set a_flag to call method "hasSourceSpecials" of a_path
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
			call method "setHasSourceSpecials:" of a_path with parameter src_flag
			set_src_special(src_flag)
		else if a_flag is 1 then
			set_src_special(true)
		else if a_flag is 0 then
			set_src_special(false)
		end if
	end if
	--log "end update_src_special_flag_from_file"
end update_src_special_flag_from_file

on open_dvi given activation:aFlag
	open_dvi of (my _dvi_driver) given sender:a reference to me, activation:aFlag
end open_dvi

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
	
	send_command of TerminalCommander for all_command
	copy TerminalCommander to a_term
	wait_termination(300) of a_term
	
	if a_pdf is missing value then
		set a_pdf to lookup_pdf_file()
	else
		if not (file_exists() of a_pdf) then
			set a_pdf to missing value
		end if
	end if
	
	--log "end of dvi_to_pdf"
	return a_pdf
end dvi_to_pdf

on lookup_pdf_file()
	--log "start lookup_pdf_file"
	set a_pdf to PDFController's make_with(a reference to me)
	a_pdf's setup()
	if file_exists() of a_pdf then
		return a_pdf
	else
		return missing value
	end if
end lookup_pdf_file

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
	script DVIController
		property _texdoc : missing value
		property _dvifile : missing value
		property _isSrcSpecial : missing value
		property _log_parser : missing value
		property _dvi_driver : SimpleDriver
	end script
	
	set_dvi_driver() of DVIController
	return DVIController
end make

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
