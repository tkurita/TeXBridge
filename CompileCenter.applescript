global EditCommands
global UtilityHandlers
global LogFileParser
global PDFController
global DVIController
global TeXDocController
global appController
global RefPanelController
global ToolPaletteController
global EditorClient

--general libs
global TerminalCommander
global PathConverter
global FrontAccess
global XFile
global PathInfo

--special values
global _com_delim
global _backslash

-- Cocoa classes
global NSUserDefaults

property _ignoring_errors : {1200, 1205, 1210, 1220, 1230, 1240}
property supportedMode : {"TEX", "LaTeX"}

on show_status_message(msg)
	appController's showStatusMessage_(msg)
end show_status_message

on rebuild_labels_from_aux(a_texdoc)
	set tex_file_path to a_texdoc's tex_file()'s posix_path()
	appController's rebuildLabelsFromAux_textEncoding_(tex_file_path, a_texdoc's text_encoding())
end rebuild_labels_from_aux

on texdoc_for_firstdoc given showing_message:message_flag, need_file:need_file_flag
	if EditorClient's exists_document() then
		set a_tex_file to EditorClient's document_file_as_alias()
		if (a_tex_file is missing value) then
			if (need_file_flag) then
				if message_flag then
					set docname to EditorClient's document_name()
					set a_message to UtilityHandlers's localized_string("DocumentIsNotSaved", {docname})
					EditorClient's show_message(a_message)
					error "The document is not saved." number 1200
				end if
				return missing value
			end if
		end if
		
		if (EditorClient's document_mode() is not in supportedMode) then
			if message_flag then
				set docname to EditorClient's document_name()
				set a_msg to UtilityHandlers's localized_string("invalidMode", {docname})
				UtilityHandlers's show_message(a_msg)
				error "The mode of the document is not supported." number 1205
			end if
			return missing value
		end if
	else
		if message_flag then
			set a_msg to localized string "noDocument"
			UtilityHandlers's show_message(a_msg)
			error "No opened documents." number 1240
		end if
		return missing value
	end if
	
	set a_texdoc to TeXDocController's make_with(a_tex_file, EditorClient's text_encoding())
	if a_tex_file is missing value then
		a_texdoc's set_filename(EditorClient's document_name())
	end if
	return a_texdoc
end texdoc_for_firstdoc

on checkmifiles given saving:savingFlag, autosave:autosaveFlag
	--log "start checkmifiles"
	
	set a_texdoc to texdoc_for_firstdoc with showing_message and need_file
	if a_texdoc is missing value then
		return missing value
	end if
	
	a_texdoc's set_doc_position(EditorClient's index_current_paragraph())
	(* find header commands *)
	set ith to 1
	repeat
		set a_paragraph to EditorClient's paragraph_at(ith)
		if a_paragraph starts with "%" then
			try
				a_texdoc's lookup_header_command(a_paragraph)
			on error msg number errno
				if errno is in {1220, 1230} then
					EditorClient's show_message(msg)
				end if
				error msg number errno
			end try
		else
			exit repeat
		end if
		set ith to ith + 1
	end repeat
	--log "after parse header commands"
	
	if savingFlag then
		if EditorClient's is_modified() then
			if not autosaveFlag then
				if not EditorClient's save_with_asking(localized string "DocumentIsModified_AskSave") then
					error "The documen is modified. Saving the document is canceld by user." number 1210
				end if
			else
				EditorClient's save_document()
			end if
		end if
	end if
	--log "end of checkmifiles"
	return a_texdoc
end checkmifiles

(* execute tex commands called from tools from mi  ====================================*)
on newLogFileParser(a_texdoc)
	--log "start newLogFileParser"
	a_texdoc's logfile()'s set_types("MMKE", "TEXT")
	return LogFileParser's make_with(a_texdoc)
end newLogFileParser

on logParseOnly()
	--log "start logParseOnly"
	set a_texdoc to prepare_typeset()
	a_texdoc's check_logfile()
	set a_log_file_parser to newLogFileParser(a_texdoc)
	parse_logfile() of a_log_file_parser
end logParseOnly

on preview_dvi_for_frontdoc()
	--log "start preview_dvi_for_frontdoc"
	try
		set a_file to (make FrontAccess)'s document_alias()
	on error number 1750
		return false
	end try
	set a_xfile to PathInfo's make_with(a_file)
	if a_xfile's path_extension() is "dvi" then
		return true
	end if
	
	set dvi_file to a_xfile's change_path_extension("dvi")
	if not dvi_file's item_exists() then
		return false
	end if
	
	set a_dvi to DVIController's make_with_xfile(dvi_file)
	--log "before open dvi"
	try
		open_dvi of a_dvi with activation
	on error msg number errno
		UtilityHandlers's show_error(errno, "preview_dvi_for_frontdoc", msg)
	end try
	--log "end preview_dvi_for_frontdoc"
	return true
end preview_dvi_for_frontdoc

on openOutputHadler(an_extension)
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in my _ignoring_errors then
			UtilityHandlers's show_error(errno, "openOutputHadler", msg)
		end if
		return
	end try
	open_outfile(an_extension) of a_texdoc
end openOutputHadler

(*== privates *)
on prepare_typeset()
	--log "start prepare_typeset"	
	set a_texdoc to checkmifiles with saving and autosave
	if a_texdoc is missing value then
		return missing value
	end if
	--log "end of checkmifiles in prepare_typeset"
	if not (a_texdoc's check_logfile()) then
		set a_path to a_texdoc's logfile()'s posix_path()
		set a_msg to UtilityHandlers's localized_string("LogFileIsOpened", {a_path})
		EditorClient's show_message(a_msg)
		return missing value
	end if
	--log "end of prepare_typeset"
	return a_texdoc
end prepare_typeset

on dvi_from_editor()
	--log "start dvi_from_editor"
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in my _ignoring_errors then
			UtilityHandlers's showError(errno, "dvi_to_pdf", msg)
		end if
		return missing value
	end try
	
	set a_dvi to lookup_dvi() of a_texdoc
	if a_dvi is missing value then
		set dviName to a_texdoc's name_for_suffix("dvi")
		set a_msg to UtilityHandlers's localized_string("DviFileIsNotFound", {dviName})
		EditorClient's show_message(a_msg)
	end if
	
	--log "end dvi_from_editor"
	return a_dvi
end dvi_from_editor

on dvi_from_frontmost()
	--log "start dvi_from_frontmost"
	set a_front to make FrontAccess
	try
		set file_url to a_front's document_url()
	on error msg number errno
		log msg
		set file_url to missing value
	end try
	if file_url is missing value then
		return missing value
	end if
	if file_url does not end with ".dvi" then
		return missing value
	end if
	
	tell current application's class "NSURL"
		set a_path to (URLWithString_(file_url)'s |path|()) as text
	end tell
	
	set a_texdoc to TeXDocController's make_with_dvifile(a_path)
	set a_dvi to a_texdoc's lookup_dvi()
	--log "end dvi_from_frontmost"
	return a_dvi
end dvi_from_frontmost

(*== actions *)
on dvi_to_pdf()
	--log "start dvi_to_pdf"
	show_status_message("Converting DVI to PDF ...")
	set a_dvi to dvi_from_frontmost()
	if a_dvi is missing value then
		set a_dvi to dvi_from_editor()
	end if
	
	if a_dvi is missing value then
		return
	end if
	
	set a_pdf to a_dvi's dvi_to_pdf()
	a_dvi's texdoc()'s preserve_terminal()
	--log "success to get PDFController"
	if a_pdf is missing value then
		EditorClient's show_message(localized string "PDFisNotGenerated")
	else
		open_pdf() of a_pdf
	end if
end dvi_to_pdf

on dvi_to_ps()
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in my _ignoring_errors then
			UtilityHandlers's show_error(errno, "dvi_to_ps", msg)
		end if
		return
	end try
	show_status_message("Converting DVI to PostScript ...")
	set a_command to a_texdoc's dvips_command()
	set cd_command to "cd " & (quoted form of (a_texdoc's cwd()'s posix_path()))
	set a_command to build_command(a_command, "dvi") of a_texdoc
	set all_command to cd_command & _com_delim & a_command
	send_command of TerminalCommander for all_command
end dvi_to_ps

--simply execute TeX command in Terminal
on exec_tex_command(texCommand, a_suffix, checkSaved)
	try
		set a_texdoc to checkmifiles without autosave given saving:checkSaved
	on error msg number errno
		if errno is not in my _ignoring_errors then
			UtilityHandlers's show_error(errno, "exec_tex_command", msg)
		end if
		return
	end try
	
	set cd_command to "cd " & (quoted form of (a_texdoc's cwd()'s posix_path()))
	set texCommand to build_command(texCommand, a_suffix) of a_texdoc
	set all_command to cd_command & _com_delim & texCommand
	send_command of TerminalCommander for all_command
end exec_tex_command

on seek_ebb()
	-- log "start seek_ebb"
	set graphicCommand to _backslash & "includegraphics"
	
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in my _ignoring_errors then
			UtilityHandlers's show_error(errno, "seek_ebb", msg)
		end if
		return
	end try
	set theOriginPath to (a_texdoc's file_ref()'s posix_path())
	PathConverter's set_base_path(theOriginPath)
	set graphicExtensions to {".pdf", ".jpg", ".jpeg", ".png"}
	set theRes to EditorClient's document_content()
	tell current application's class "NSUserDefaults"
		tell its standardUserDefaults()
			set ebb_command to stringForKey_("ebbCommand") as text
		end tell
	end tell
	if ebb_command contains "-m" then
		set bb_ext to "bb"
	else
		set bb_ext to "xbb"
	end if
	--find graphic files
	set noGraphicFlag to true
	set noNewBBFlag to true
	set a_term to make TerminalCommander
	repeat with ith from 1 to (count paragraph of theRes)
		set a_paragraph to paragraph ith of theRes
		if ((length of a_paragraph) > 1) and (a_paragraph does not start with "%") then
			set a_path to filepath_in_command(graphicCommand, a_paragraph) of EditCommands
			repeat with an_extension in graphicExtensions
				if a_path ends with an_extension then
					set noGraphicFlag to false
					if exec_ebb(a_path, bb_ext, a_term, ebb_command) then
						set noNewBBFlag to false
					end if
					exit repeat
				end if
			end repeat
		end if
	end repeat
	TerminalCommander's register_from_commander(a_term)
	if noGraphicFlag then
		set a_msg to UtilityHandlers's localized_string("noGraphicFile", {a_texdoc's a_name()})
		EditorClient's show_message(a_msg)
	else if noNewBBFlag then
		EditorClient's show_message(localized string "bbAlreadyCreated")
	end if
end seek_ebb

on need_update_bb(graphic_file, bb_file)
	-- log "start need_update_bb"
	if bb_file's item_exists() then
		set bb_mod to modification date of (bb_file's info())
		set g_mod to modification date of (graphic_file's info())
		if (bb_mod > g_mod) then
			return false
		end if
	end if
	-- log "end need_update_bb"
	return true
end need_update_bb

on exec_ebb(graphic_path, bb_ext, a_term, ebb_command)
	-- log "start exec_bb"
	set graphic_file to XFile's make_with(graphic_path)
	set bb_file to graphic_file's change_path_extension(bb_ext)
	
	if not need_update_bb(graphic_file, bb_file) then return false
	
	set target_dir to graphic_file's parent_folder()'s posix_path()
	set a_name to graphic_file's item_name()
	
	set cd_command to "cd '" & target_dir & "'"
	set all_command to cd_command & _com_delim & ebb_command & space & "'" & a_name & "'"
	send_command of a_term for all_command
	a_term's wait_termination(300)
	-- log "end exec_bb"
	return true
end exec_ebb

on mendex()
	--log "start execmendex"
	tell NSUserDefaults's standardUserDefaults()
		set a_command to stringForKey_("mendexCommand") as text
	end tell
	exec_tex_command(a_command, "idx", false)
end mendex

on bibtex()
	tell NSUserDefaults's standardUserDefaults()
		set a_command to stringForKey_("bibtexCommand") as text
	end tell
	exec_tex_command(a_command, missing value, true)
end bibtex

on quick_typeset_preview()
	--log "start quick_typeset_preview"
	try
		set a_texdoc to prepare_typeset()
	on error msg number errno
		if errno is not in my _ignoring_errors then
			UtilityHandlers's show_error(errno, "quick_typeset_preview after calling prepare_typeset", msg)
		end if
		return
	end try
	
	if a_texdoc is missing value then
		return
	end if
	
	a_texdoc's set_use_term(false)
	show_status_message("Typeseting...")
	--log "before typeset in quick_typeset_preview"
	try
		set a_dvi to a_texdoc's typeset()
	on error number 1250
		return
	end try
	--log "after typeset in quick_typeset_preview"
	show_status_message("Analyzing log text ...")
	set a_log_file_parser to newLogFileParser(a_texdoc)
	--log "befor parseLogText in quick_typeset_preview"
	a_log_file_parser's parseLogText()
	-- log "after parseLogText in quick_typeset_preview"
	show_status_message("Opening DVI file  ...")
	set a_flag to a_log_file_parser's is_no_error()
	if a_log_file_parser's is_dvi_output() then
		try
			open_dvi of a_dvi given activation:a_flag
		on error msg number errno
			show_error(errno, "quick_typeset_preview after calling open_dvi", msg) of UtilityHandlers
		end try
	else
		set a_msg to localized string "DVIisNotGenerated"
		UtilityHandlers's show_message(a_msg)
	end if
	if not a_flag then
		tell current application's class "LogWindowController"
			its sharedLogManager()'s bringToFront()
		end tell
		activate
	end if
	a_texdoc's preserve_terminal()
	--log "before rebuild_labels_from_aux in quick_typeset_preview"
	rebuild_labels_from_aux(a_texdoc)
	--log "after rebuild_labels_from_aux in quick_typeset_preview"
	show_status_message("")
end quick_typeset_preview

on typeset_preview()
	set a_dvi to typeset()
	
	show_status_message("Opening DVI file ...")
	set activate_flag to false
	if a_dvi is not missing value then
		set activate_flag to a_dvi's log_parser()'s is_no_error()
		try
			open_dvi of a_dvi given activation:activate_flag
		on error msg number errno
			show_error(errno, "typeset_preview", msg) of UtilityHandlers
		end try
	end if
	a_dvi's texdoc()'s preserve_terminal()
end typeset_preview

on typeset_preview_pdf()
	set a_dvi to typeset()
	
	if a_dvi is missing value then
		return
	end if
	set a_pdf to a_dvi's dvi_to_pdf()
	a_dvi's texdoc()'s preserve_terminal()
	show_status_message("Opening PDF file ...")
	if a_pdf is missing value then
		set a_msg to localized string "PDFisNotGenerated"
		show_message(a_msg) of UtilityHandlers
	else
		open_pdf() of a_pdf
	end if
end typeset_preview_pdf

on do_typeset()
	set a_dvi to typeset()
	if a_dvi is missing value then
		return
	end if
	a_dvi's texdoc()'s preserve_terminal()
end do_typeset

on typeset()
	--log "start typeset"
	try
		set a_texdoc to prepare_typeset()
	on error msg number errno
		if errno is not in my _ignoring_errors then
			show_error(errno, "typeset after calling prepare_typeset", msg) of UtilityHandlers
		end if
		return missing value
	end try
	if a_texdoc is missing value then
		return missing value
	end if
	show_status_message("Typeseting...")
	try
		set a_dvi to a_texdoc's typeset()
	on error number 1250
		return missing value
	end try
	set a_log_file_parser to newLogFileParser(a_texdoc)
	show_status_message("Analyzing log text ...")
	parse_logfile() of a_log_file_parser
	tell NSUserDefaults's standardUserDefaults()
		set autoMultiTypeset to boolForKey_("AutoMultiTypeset") as boolean
	end tell
	if (autoMultiTypeset and (a_log_file_parser's labels_changed())) then
		show_status_message("Typeseting...")
		try
			set a_dvi to a_texdoc's typeset()
		on error number 1250
			return missing value
		end try
		show_status_message("Analyzing log text ...")
		parse_logfile() of a_log_file_parser
	end if
	
	-- log "befor rebuild_labels_from_aux in typeset"
	rebuild_labels_from_aux(a_texdoc)
	-- log "after rebuild_labels_from_aux in typeset"
	show_status_message("")
	a_dvi's set_log_parser(a_log_file_parser)
	if (not (a_log_file_parser's is_no_error())) then
		tell current application's class "SmartActivate"
			its activateSelf()
		end tell
	end if
	if (is_dvi_output() of a_log_file_parser) then
		return a_dvi
	else
		set a_msg to localized string "DVIisNotGenerated"
		show_message(a_msg) of UtilityHandlers
		return missing value
	end if
end typeset

on preview_dvi()
	--log "start preview_dvi"
	if not EditorClient's is_frontmost() then
		if preview_dvi_for_frontdoc() then return
	end if
	
	try
		set a_texdoc to checkmifiles without saving and autosave
		--a_texdoc's set_use_term(false)
		a_texdoc's set_use_term(true)
	on error msg number errno
		if errno is not in my _ignoring_errors then
			show_error(errno, "preview_dvi", msg) of UtilityHandlers
		end if
		return
	end try
	--log "before lookup_dvi"
	show_status_message("Opening DVI file ...")
	set a_dvi to a_texdoc's lookup_dvi()
	--log "before open_dvi"
	if a_dvi is not missing value then
		try
			open_dvi of a_dvi with activation
		on error msg number errno
			show_error(errno, "preview_dvi", msg) of UtilityHandlers
		end try
	else
		set dviName to name_for_suffix("dvi") of a_texdoc
		set a_msg to UtilityHandlers's localized_string("DviFileIsNotFound", {dviName})
		EditorClient's show_message(a_msg)
	end if
	--log "end preview_dvi"
end preview_dvi

on preview_pdf()
	
	try
		set a_texdoc to checkmifiles without saving and autosave
	on error msg number errno
		if errno is not in my _ignoring_errors then
			show_error(errno, "preview_dvi", msg) of UtilityHandlers
		end if
		return
	end try
	show_status_message("Opening PDF file ...")
	set a_pdf to PDFController's make_with(a_texdoc)
	a_pdf's setup()
	if file_exists() of a_pdf then
		open_pdf() of a_pdf
	else
		EditorClient's show_message(localized string "noPDFfile")
	end if
end preview_pdf
