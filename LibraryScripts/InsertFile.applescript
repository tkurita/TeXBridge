property EnvScanner : module
property ScannerSource : module
property EditorClient : module "miClient"
property TeXBridgeProxy : module
property PathConverter : module
property XText : module
--property PathInfo : module

property _texbridge : missing value

property _graphicFileSuffixes : {"eps", "pdf", "png", "jpg", "jpeg"}
property _bib_suffixes : {"bib"}

property _float_enviroments : {"figure", "wrapfigure"}
property _figlabel_prefix : "fig:"

(* values in plist file *)
property _backslash : character id 92
property _incGraphicCommand : _backslash&"includegraphics"
property _incGraphicBlock : missing value
--property _labelCommand : _backslash&"label"
property _labelBracket : _backslash&"label{"
property _beginBracket : _backslash&"begin{"
property _endBracket : _backslash&"end{"
property _scanner_source : missing value
property _env_scanner: missing value


on debug()
	set loader to boot (module loader of application (get "TeXToolsLib")) for me
	set PathInfo to loader's load("PathInfo")
	
	set target_file to EditorClient's document_file_as_alias()
	if target_file is missing value then
		set docname to EditorClient's document_name()
		display alert my _texbridge's localized_string("DocumentIsNotSaved", {docname})
		return
	end if
	
	set target_file to PathInfo's make_with(target_file)
	set a_folder to target_file's parent_folder()
	
	set a_file to choose file with prompt "Choose a file to insert." default location a_folder's as_alias() without invisibles
	tell make_with_texbridge(make TeXBridgeProxy)
		do(PathInfo's make_with(a_file), target_file)
	end tell
end debug

on debug2()
	set loader to boot (module loader of application (get "TeXToolsLib")) for me
	set my _texbridge to make TeXBridgeProxy
	EnvScanner's initialize()
	is_in_float_env()
end debug2

on debug3()
	set loader to boot (module loader of application (get "TeXToolsLib")) for me
	set PathInfo to loader's load("PathInfo")
	
	set target_file to EditorClient's document_file_as_alias()
	set insert_file to PathInfo's make_with("/Users/tkurita/WorkSpace/加速器勉強会/イオン源プラズマ-slide/figure/parallel-magnetic-field.pdf")
	tell make_with_texbridge(make TeXBridgeProxy)
		do(insert_file, PathInfo's make_with(target_file))
	end tell
end debug3

on run
	debug3()
	--debug2()
	--debug()
end run

on make
	set a_class to me
	script InsertFileInstance
		property parent : a_class
		property _texbridge : missing value
		property _scanner_source : make ScannerSource
		property _env_scanner : missing value
		property _incGraphicBlock : my _incGraphicBlock
		property _incGraphicCommand : my _incGraphicCommand
		property _labelBracket : my _labelBracket
		property _beginBracket : my _beginBracket
		property _endBracket : my _endBracket
	end script
	return InsertFileInstance
end make

on make_with_texbridge(a_texbridge)
	tell (make)
		set its _texbridge to a_texbridge
		return it
	end tell
end make_with_texbridge

on set_compile_server(an_object)
	set my _texbridge to an_object
end set_compile_server

on replace_paragraph(a_text, selection_rec)
	EditorClient's set_paragraph_at(a_text, paragraphIndex of selection_rec)
	set decrement_pos to 0
	set new_text_len to length of a_text
	--log a_text
	--log new_text_len
	--log cursorInParagraph of selection_rec
	if (cursorInParagraph of selection_rec) > (new_text_len - 1) then
		set decrement_pos to (cursorInParagraph of selection_rec) - (new_text_len - 1)
	end if
	--log decrement_pos
	EditorClient's set_insertion_point_at((cursorPosition of selection_rec) - decrement_pos)
end replace_paragraph

on insert_source(a_pathinfo)
	set rel_path_no_suffix to relative_path of PathConverter for a_pathinfo's change_path_extension(missing value)'s posix_path()
	set rel_path to relative_path of PathConverter for a_pathinfo's posix_path()
	set a_suffix to a_pathinfo's path_extension()
	set selection_rec to EditorClient's selection_info()
	set include_command to my _texbridge's plist_value("includeCommand")
	set input_command to my _texbridge's plist_value("inputCommand")
	
	set new_text to change_command_param(include_command, currentParagraph of selection_rec, cursorInParagraph of selection_rec, rel_path_no_suffix)
	if new_text is missing value then
		if a_suffix is "tex" then
			set a_rel_path to rel_path_no_suffix
		else
			set a_rel_path to rel_path
		end if
		set new_text to change_command_param(include_command, currentParagraph of selection_rec, cursorInParagraph of selection_rec, a_rel_path)
	else
		if a_suffix is not "tex" then
			display alert (my _texbridge's localized_string("'include' command can accept only a file of which path extension is '.tex'.", {}))
			return
		end if
	end if
	
	if new_text is missing value then
		set a_list to choose from list {include_command, input_command} default items {include_command}
		if class of a_list is list then
			set a_command to item 1 of a_list
			if a_suffix is "tex" then
				set a_rel_path to rel_path_no_suffix
			else
				if a_command is include_command then
					display alert (my _texbridge's localized_string("'include' command can accept only a file of which path extension is '.tex'.", {}))
					return
				end if
				set a_rel_path to rel_path
			end if
			EditorClient's insert_text(a_command & "{" & a_rel_path & "}")
		end if
	else
		replace_paragraph(new_text, selection_rec)
	end if
	
end insert_source

on insert_graphic(a_pathinfo)
	set rel_path to relative_path of PathConverter for a_pathinfo's posix_path()
	set my _env_scanner to EnvScanner's make_with(my _texbridge)
	set my _incGraphicCommand to my _texbridge's plist_value("incGraphicCommand")
	set my _beginBracket to (my _env_scanner's begin_text() & "{")
	set my _endBracket to (my _env_scanner's end_text() & "{")
	set label_name to XText's make_with(_figlabel_prefix & a_pathinfo's basename())'s replace("_", "-")'s as_unicode()
	if not change_graphic_command(rel_path, label_name) then
		insert_graphic_commands(rel_path, label_name)
	end if
end insert_graphic

on insert_bib(a_pathinfo)
	set rel_path_no_suffix to relative_path of PathConverter for a_pathinfo's change_path_extension(missing value)'s posix_path()
	set selection_rec to EditorClient's selection_info()
	set bib_command to my _texbridge's plist_value("bibliographyCommand")
	set new_text to change_command_param(bib_command, currentParagraph of selection_rec, cursorInParagraph of selection_rec, rel_path_no_suffix)
	
	if new_text is missing value then
		EditorClient's insert_text(bib_command & "{" & rel_path_no_suffix & "}")
	else
		replace_paragraph(new_text, selection_rec)
	end if
	
end insert_bib

on do(a_pathinfo, tex_file)
	--set my _texbridge to TeXBridgeProxy's shared_instance()
	my _texbridge's resolve_support_plist()
	PathConverter's set_base_path(tex_file's posix_path())
	set a_suffix to a_pathinfo's path_extension()
	if a_suffix is in my _graphicFileSuffixes then
		insert_graphic(a_pathinfo)
	else if a_suffix is in my _bib_suffixes then
		insert_bib(a_pathinfo)
	else
		insert_source(a_pathinfo)
	end if
	
	return true
end do

on is_in_float_env()
	if my _scanner_source's cursor_position() is 1 then
		return false
	end if
	set beg_rec to my _env_scanner's find_begin()
	
	repeat 5 times
		if beg_rec is missing value then
			return false
		end if
		
		set env_name to enviroment of beg_rec
		if env_name is in my _float_enviroments then
			return true
		else if env_name is "document" then
			return false
		end if
		set beg_rec to my _env_scanner's find_next_begin()
	end repeat
	
	return false
end is_in_float_env

on insert_graphic_commands(graphicPath, labelName)
	set my _incGraphicBlock to my _texbridge's plist_value("incGraphicBlock")
	set a_text to XText's make_with(my _incGraphicBlock)'s format_with({graphicPath, labelName})
	if not is_in_float_env() then
		set fig_env to my _texbridge's plist_value("figEnvBlock")
		set a_text to XText's make_with(fig_env)'s format_with({a_text})
	end if
	
	EditorClient's insert_text(a_text's as_unicode())
end insert_graphic_commands

on change_parameter(target_text, new_value, a_pos)
	set open_bracket_pos to offset of "{" in target_text
	set close_bracket_pos to offset of "}" in target_text
	if 0 is in {open_bracket_pos, close_bracket_pos} then
		error "No brackets for a parameter." number 1311
	end if
	
	if a_pos > -1 then
		if a_pos is less than open_bracket_pos then
			error "The position is not placed on a parameter." number 1310
		else if a_pos is greater than or equal to close_bracket_pos then
			error "The position is out of brackets." number 1312
		end if
	end if
	
	set pre_text to text 1 thru open_bracket_pos of target_text
	set post_text to text close_bracket_pos thru -1 of target_text
	set new_text to pre_text & new_value & post_text
end change_parameter

on findCommandInSameEnvBefore(target_text, targetCommand, new_value)
	set com_pos to offset of (command) in target_text
	set endEnvPosition to offset of my _endBracket in target_text
	
	if endEnvPosition < com_pos then
		set pre_text to text 1 thru com_pos of target_text
		set target_text to text (com_pos + 1) thru -1 of target_text
		set new_text to change_parameter(target_text, new_value, -1)
		return pre_text & new_text
	else
		return 0
	end if
end findCommandInSameEnvBefore

on findCommandInSameEnvAfter(target_text, targetCommand, new_value)
	set com_pos to offset of targetCommand in target_text
	set beginEnvPosition to offset of my _beginBracket in target_text
	
	if (beginEnvPosition is 0) or (com_pos < beginEnvPosition) then
		set pre_text to text 1 thru com_pos of target_text
		set target_text to text (com_pos + 1) thru -1 of target_text
		set new_text to change_parameter(target_text, new_value, -1)
		return pre_text & new_text
	else
		return 0
	end if
end findCommandInSameEnvAfter

(*
@param a_command : ex) "input"
@param a_tex : 
@param a_pos : caret position in a_text. The caret at the beginning of a_text is 0.
@param a_path : a relative path
*)
on change_command_param(a_command, a_text, a_pos, a_path)
	set com_pos to offset of a_command in a_text
	if com_pos is 0 then
		return missing value
	end if
	set pre_text to text 1 thru com_pos of a_text
	set post_text to text (com_pos + 1) thru -1 of a_text
	set a_pos to a_pos - (length of pre_text)
	try
		set new_text to change_parameter(post_text, a_path, a_pos)
	on error msg number errno
		if errno is in {1310, 1311} then
			return missing value
		else if errno is 1312 then
			set new_text to change_command_param(a_command, post_text, a_pos, a_path)
		else
			error msg number errno
		end if
	end try
	
	if new_text is missing value then
		return missing value
	end if
	
	return (pre_text & new_text)
end change_command_param

on change_graphic_command(graphicPath, labelName)
	set selection_rec to my _scanner_source's selection_info()
	set current_line to my _scanner_source's current_text()
	set new_text to change_command_param(my _incGraphicCommand, current_line, cursorInParagraph of selection_rec, graphicPath)
	if new_text is missing value then
		return false
	end if
	--EditorClient's set_paragraph_at(new_text, par_position)
	replace_paragraph(new_text, selection_rec)
	
	set label_command to my _texbridge's plist_value("labelText")
	set my _labelBracket to (label_command & "{")
	repeat with ith from (selection_rec's paragraphIndex) to (selection_rec's paragraphIndex) + 5
		set a_line to EditorClient's paragraph_at(ith)
		
		if a_line contains my _labelBracket then
			set new_text to findCommandInSameEnvAfter(a_line, label_command, labelName)
			if new_text is 0 then
				exit repeat
			else
				EditorClient's set_paragraph_at(new_text, ith)
				return true
			end if
		end if
	end repeat
	
	repeat with ith from par_position to par_position - 5
		set a_line to EditorClient's paragraph_at(ith)
		
		if a_line contains labelComannd then
			set new_text to findCommandInSameEnvBefore(a_line, label_command, labelName)
			if new_text is 0 then
				exit repeat
			else
				EditorClient's set_paragraph_at(new_text, ith)
				return true
			end if
		end if
	end repeat
	return true
end change_graphic_command
