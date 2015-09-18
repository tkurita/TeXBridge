property TeXBridgeProxy : module
property EditorClient : module "miClient"
property PathConverter : module
property _graphic_suffixes : {".pdf", ".eps", ".png", ".jpg", ".jpeg"}

property _is_graphic : false

on make
	set a_class to me
	script InsertedFileParserInstance
		property parent : a_class
		property _texbridge : missing value
		property _is_graphic : my _is_graphic
	end script
	return InsertedFileParserInstance
end make

on make_with_texbridge(a_texbridge)
	tell (make)
		set its _texbridge to a_texbridge
		return it
	end tell
end make_with_texbridge

on is_graphic()
	return my _is_graphic
end is_graphic

on extract_filepath(a_command, a_paragraph)
	if a_paragraph contains a_command then
		set pos0 to offset of a_command in a_paragraph
		set a_paragraph to text pos0 thru -1 of a_paragraph
		set pos1 to offset of "{" in a_paragraph
		set pos2 to offset of "}" in a_paragraph
		set thePath to text (pos1 + 1) thru (pos2 - 1) of a_paragraph
		set full_path to absolute_path of PathConverter for thePath
	else
		set full_path to ""
	end if
	return full_path
end extract_filepath


on do()
	set a_file to EditorClient's document_file_as_alias()
	if a_file is missing value then
		set docname to EditorClient's document_name()
		display alert my _texbridge's localized_string("DocumentIsNotSaved", {docname})
		return
	end if
	
	--log "start openRelatedFile"
	set_base_path(POSIX path of a_file) of PathConverter
	tell my _texbridge
		resolve_support_plist()
		set backslash to plist_value("backslash")
		set incGraphicCommand to plist_value("incGraphicCommand")
	end tell
	set bibCommand to backslash & "bibliography"
	set commandList to {incGraphicCommand, backslash & "input", backslash & "include", bibCommand}
	
	set firstpara to EditorClient's index_current_paragraph()
	set paracount to count paragraphs of contents of selection_ref() of EditorClient
	repeat with nth from firstpara to firstpara + paracount - 1
		set a_paragraph to EditorClient's paragraph_at(nth)
		if ((length of a_paragraph) > 1) and (a_paragraph does not start with "%") then
			repeat with a_command in commandList
				set full_path to my extract_filepath(a_command, a_paragraph)
				if full_path is not "" then
					try
						set file_alias to (POSIX file full_path) as alias
					on error
						if (a_command as Unicode text) is bibCommand then
							set suffixes to {".bib"}
							--set path_with_suffix to full_path & ".bib"
						else if (a_command as Unicode text) is incGraphicCommand then
							set suffixes to my _graphic_suffixes
						else
							set suffixes to {".tex"}
							--set path_with_suffix to full_path & ".tex"
						end if
						repeat with a_suffix in suffixes
							set path_with_suffix to full_path & a_suffix
							try
								set file_alias to (POSIX file path_with_suffix) as alias
								exit repeat
							on error
								set file_alias to missing value
							end try
						end repeat
						if file_alias is missing value then
							set a_msg to my _texbridge's localized_string("FileIsNotFound", path_with_suffix)
							error a_msg number 1320
							return
						end if
					end try
					set my _is_graphic to contents of a_command is incGraphicCommand
					return {command:contents of a_command, file:file_alias}
					exit repeat
				end if
			end repeat
		end if
	end repeat
	return missing value
end do

on graphic_suffixes()
	return my _graphic_suffixes
end graphic_suffixes


on debug()
	boot (module loader of application (get "TeXToolsLib")) for me
	do()
end debug

on run
	--return debug()
	do()
end run
