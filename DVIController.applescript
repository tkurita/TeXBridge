global UtilityHandlers
global TerminalCommander
global PDFController
global PathConverter

global comDelim

script XdviDriver
	on set_file_type(dviFileRef)
		-- do nothing
	end set_file_type
	
	on openDVI given sender:a_dvi, activation:aFlag
		set x11AppName to "X11"
		if not (isRunning(x11AppName) of UtilityHandlers) then
			tell application x11AppName
				launch
			end tell
		end if
		set a_texdoc to a_dvi's texdoc()
		update_src_special_flag_from_file() of a_dvi
		set cdCommand to "cd " & (quoted form of (a_dvi's pwd()'s posix_path()))
		set dviFileName to a_dvi's fileName()
		
		set dviViewCommand to contents of default entry "dviViewCommand" of user defaults
		if (a_dvi's src_special()) and (a_texdoc is not missing value) then
			if a_texdoc's has_parent() then
				set_base_path(a_texdoc's file_ref()'s posix_path()) of PathConverter
				set sourceFile to relative_path of PathConverter for (texdoc()'s target_file()'s posix_path())
			else
				set sourceFile to a_dvi's texdoc()'s fileName()
			end if
			
			set allCommand to cdCommand & comDelim & dviViewCommand & " -sourceposition '" & (a_texdoc's doc_position()) & space & sourceFile & "' '" & dviFileName & "' &"
			doCommands of TerminalCommander for allCommand without activation
		else
			try
				set pid to do shell script "ps -o pid,command|awk '/xdvi.bin.*" & dviFileName & "$/{print $1}'"
			on error errMsg number 1
				set pid to ""
			end try
			
			if pid is "" then
				set allCommand to cdCommand & comDelim & dviViewCommand & space & "'" & dviFileName & "' &"
				doCommands of TerminalCommander for allCommand without activation
			else
				set pid to word 1 of pid
				do shell script "kill -USR1" & space & pid --reread
			end if
		end if
	end openDVI
end script

script SimpleDriver
	on set_file_type(dviFileRef)
		-- do nothing
	end set_file_type
	
	on openDVI given sender:a_dvi, activation:aFlag
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
	end openDVI
end script

script MxdviDriver
	on set_file_type(a_dvi)
		a_dvi's set_types("Mxdv", "JDVI")
	end set_file_type
	
	on openDVI given sender:a_dvi, activation:aFlag
		--log "start openDVI of MxdviDriver"
		try
			set mxdviApp to path to application "Mxdvi" as alias
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
			set all_command to mxdviPath & "  -sourceposition " & (a_texdoc's doc_position()) & space & targetDviPath
			--log all_command
			if a_texdoc's is_use_term() then
				doCommands of TerminalCommander for all_command without activation
			else
				do shell script all_command
			end if
		else
			tell application (mxdviApp as Unicode text)
				if aFlag then activate
				open a_dvi's file_as_alias()
			end tell
		end if
		--log "end openDVI"
	end openDVI
end script



on fileName()
	if my _dvifile is not missing value then
		return my _dvifile's item_name()
	end if
	return my _texdoc's name_for_suffix(".dvi")
end fileName

on texdoc()
	return my _texdoc
end texdoc

on pwd()
	if my _texdoc is not missing value then
		return my _texdoc's pwd()
	end if
	
	return my _dvifile's parent_folder()
end pwd

on posix_path()
	return my _dvifile's posix_path()
end posix_path

on file_as_alias()
	if my _dvifile is missing value then
		set an_alias to my _texdoc's tex_file()'s change_path_extension(".dvi")'s as_alias()
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
	else
		--log "DVI Preview setting is invalid."
		error "DVI Preview setting is invalid." number 1290
	end if
	--log "end set_dvi_driver"
end set_dvi_driver

on getModDate()
	return modification date of (my _dvifile's info())
end getModDate

on set_src_special_flag()
	if (my _texdoc's typeset_command()) contains "-src" then
		set_src_special(true)
		ignoring application responses
			tell application "Finder"
				set comment of (my _dvifile's as_alias()) to "Source Specials"
			end tell
		end ignoring
	else
		set_src_special(false)
		ignoring application responses
			tell application "Finder"
				set comment of my _dvifile's as_alias() to ""
			end tell
		end ignoring
	end if
end set_src_special_flag

on update_src_special_flag_from_file()
	if src_special() is missing value then
		tell application "Finder"
			set comment_text to comment of (my _dvifile's as_alias())
		end tell
		set_src_special(comment_text starts with "Source Special")
	end if
end update_src_special_flag_from_file

on openDVI given activation:aFlag
	openDVI of (my _dvi_driver) given sender:a reference to me, activation:aFlag
end openDVI

on dvi_to_pdf()
	--log "start dvi_to_pdf"
	set a_pdf to lookupPDFFile()
	--log "success lookupPDFFile"
	--check busy status of pdf file.
	if a_pdf is not missing value then
		if not prepareDVItoPDF() of a_pdf then
			return missing value
		end if
	end if
	
	--log "convert a DVI file into a PDF file"
	if (my dvipdfCommand is missing value) then
		set theCommand to contents of default entry "dvipdfCommand" of user defaults
	else
		set theCommand to my dvipdfCommand
	end if
	set cdCommand to "cd" & space & (quoted form of (pwd()'s posix_path()))
	set targetFileName to name_for_suffix(".dvi")
	set allCommand to cdCommand & comDelim & theCommand & space & "'" & targetFileName & "'"
	
	sendCommands of TerminalCommander for allCommand
	copy TerminalCommander to currentTerminal
	waitEndOfCommand(300) of currentTerminal
	
	if a_pdf is missing value then
		set a_pdf to lookupPDFFile()
	else
		if not (isExistPDF() of a_pdf) then
			set a_pdf to missing value
		end if
	end if
	
	--log "end of dvi_to_pdf"
	return a_pdf
end dvi_to_pdf

on lookupPDFFile()
	--log "start lookupPDFFile"
	set a_pdf to PDFController's make_with(a reference to me)
	a_pdf's setup()
	if isExistPDF() of a_pdf then
		return a_pdf
	else
		return missing value
	end if
end lookupPDFFile

on set_dvifile(a_xfile)
	set my _dvifile to a_xfile
end set_dvifile

on make
	script DVIController
		property _texdoc : missing value
		property _dvifile : missing value
		property _isSrcSpecial : missing value
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