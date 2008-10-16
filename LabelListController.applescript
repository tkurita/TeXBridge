global _backslash

global XDict
global XText
global PathConverter
global PathAnalyzer
global XList

global RefPanelController
global EditorClient
global TeXDocController
global AuxData
global CompileCenter

(*
property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property XDict : load script file (LibraryFolder & "XDict.scpt")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer.scpt")
property PathConverter : load script file (LibraryFolder & "PathConverter.scpt")
*)

property _aux_data_dict : missing value
property _label_data_source : missing value
property _unsaved_auxdata : missing value

property _ignoring_errors : {1230, 1500}

on initialize(theDataSource)
	set my _aux_data_dict to make XDict
	set my _label_data_source to theDataSource
	tell my _label_data_source
		make new data column at the end of the data columns with properties {name:"label"}
		make new data column at the end of the data columns with properties {name:"reference"}
	end tell
end initialize

on watchmi given force_reloading:force_flag
	--log "start watchmi in LabelListController"
	try
		with timeout of 2 seconds
			set an_auxdata to find_auxdata_from_doc()
		end timeout
	on error msg number errno
		if errno is in {1230, 1500, -1712} then
			-- 1230 : ParentFile is invalid.
			-- 1500 : Unsupported File.
			-- -1712 : timeout
			return
		else
			error "Fail to find_auxdata_from_doc in watchmi of LabelListController." & return & msg number errno
		end if
	end try
	
	if an_auxdata is missing value then
		return
	end if
	
	if an_auxdata's data_item() is missing value then
		--log "no data item"
		if an_auxdata's aux_file() is not missing value then
			parse_aux_file(an_auxdata)
		end if
		find_labels_from_doc(an_auxdata, force_flag)
		if an_auxdata's has_parent() then
			--log "has ParentFile"
			set a_parentdoc to TeXDocController's make_with(an_auxdata's tex_file(), an_auxdata's text_encoding())
			set a_parentaux to auxdata_for_texdoc(a_parentdoc)
			if a_parentaux's data_item() is missing value then
				if (check_auxfile of a_parentaux without display_error) then
					parse_aux_file(a_parentaux)
				end if
			end if
			append_to_outline for a_parentaux below my _label_data_source
			an_auxdata's expandDataItem()
		else
			--log "no ParentFile"
			append_to_outline for an_auxdata below my _label_data_source
		end if
	else
		--log "has data items"
		set expanded_flag to an_auxdata's is_expanded()
		if force_flag then
			--log "force update"
			if (check_auxfile of an_auxdata without display_error) then
				parse_aux_file(an_auxdata)
				an_auxdata's clear_labels_from_doc()
				append_to_outline for an_auxdata below my _label_data_source
			end if
		end if
		
		if find_labels_from_doc(an_auxdata, force_flag) then
			--log "before update_labels_from_doc"
			an_auxdata's update_labels_from_doc()
		else
			--log "skip update_labels_from_doc"
		end if
		if expanded_flag then
			an_auxdata's expandDataItem()
		end if
		
	end if
end watchmi

on find_auxdata_from_doc()
	--log "start find_auxdata_from_doc"
	set a_texdoc to texdoc_for_firstdoc of CompileCenter without showing_message and need_file
	if a_texdoc is missing value then
		return missing value
	end if
	
	if (not a_texdoc's has_file()) then
		return auxdata_for_texdoc(a_texdoc)
	end if
	
	--log "start finding ParentFile"
	set ith to 1
	repeat
		set a_paragraph to paragraph_at_index(ith) of EditorClient
		if a_paragraph starts with "%" then
			if a_paragraph starts with "%ParentFile" then
				try
					set a_file to a_texdoc's resolve_parent(a_paragraph)
				on error msg number errno
					if errno is 1230 then
						RefPanelController's display_alert(msg)
					end if
					error msg number errno
				end try
				a_texdoc's update_with_parent(a_file)
				
				exit repeat
			end if
			set ith to ith + 1
		else
			exit repeat
		end if
	end repeat
	--log "end finding ParentFile"
	
	--log "end  find_auxdata_from_doc"
	return auxdata_for_texdoc(a_texdoc)
end find_auxdata_from_doc

on append_to_outline for an_auxdata below parentDataItem
	--log "start append_to_outline"
	if an_auxdata's data_item() is missing value then
		--log "is first append to outline"
		set titleItem to make new data item at end of data items of parentDataItem
		an_auxdata's set_data_item(titleItem)
		set contents of data cell "label" of titleItem to an_auxdata's basename()
	else
		--log "before updateLabels in append_to_outline"
		updateLabels() of an_auxdata
		return
	end if
	
	--log "before repeat in append_to_outline"
	repeat with theLabelRecord in an_auxdata's all_label_records()
		repeat with ith from 1 to length of theLabelRecord
			set theItem to item ith of theLabelRecord
			set theClass to class of theItem
			if theClass is record then
				set theDataItem to make new data item at end of data items of titleItem
				set contents of data cell "label" of theDataItem to |label| of theItem
				set contents of data cell "reference" of theDataItem to |reference| of theItem
			else if theClass is script then
				append_to_outline for theItem below titleItem
			end if
		end repeat
	end repeat
	an_auxdata's expandDataItem()
	--log "end appndToOutline"
end append_to_outline

on auxdata_for_texdoc(a_texdoc)
	--log "start auxdata_for_texdoc"
	if a_texdoc's has_file() then
		--log "file is saved"
		set a_key to a_texdoc's no_suffix_target_path()
		--log "auxdata key: " & a_key
		try
			set an_auxdata to my _aux_data_dict's value_for_key(a_key)
			an_auxdata's set_texdoc(a_texdoc) -- update for text encoding		
		on error number 900
			set an_auxdata to AuxData's make_with_texdoc(a_texdoc)
			my _aux_data_dict's set_value(a_key, an_auxdata)
		end try
		(*
		if an_auxdata is missing value then
			--log "new auxdata will be registered"
			set an_auxdata to AuxData's make_with_texdoc(a_texdoc)
			my _aux_data_dict's set_value(a_key, an_auxdata)
		else
			an_auxdata's set_texdoc(a_texdoc) -- update for text encoding
		end if
		*)
	else
		--log "file is not saved"
		if my _unsaved_auxdata is not missing value then
			my _unsaved_auxdata's deleteDataItem()
		end if
		set an_auxdata to AuxData's make_with_texdoc(a_texdoc)
		set my _unsaved_auxdata to an_auxdata
	end if
	
	--log "end auxdata_for_texdoc"
	return an_auxdata
end auxdata_for_texdoc

on parse_aux_file(an_auxdata)
	--log "start parse_aux_file"
	set doc_content to read_aux_file() of an_auxdata
	--log "before clearLabelsFromAux in parse_aux_file"
	clearLabelsFromAux() of an_auxdata
	--log "start repeat in parse_aux_file"
	set newlabelText to _backslash & "newlabel{"
	set inputText to _backslash & "@input{"
	repeat with ith from 1 to (count paragraph of doc_content)
		set a_paragraph to paragraph ith of doc_content
		--log a_paragraph
		if (a_paragraph as Unicode text) starts with newlabelText then
			--log "start with newlabelText"
			set a_paragraph to text 11 thru -2 of a_paragraph
			set theTextItemList to XText's make_with(a_paragraph)'s as_list_with("}{")
			try
				set theRef to ((item -2 of theTextItemList) as string)
			on error
				set theRef to "--"
			end try
			
			set pos2 to (offset of "}{" in a_paragraph) as integer
			set a_label to item 1 of theTextItemList
			
			if not a_label is "" then
				addLabelFromAux(a_label, theRef) of an_auxdata
			end if
		else if a_paragraph starts with inputText then
			--log "start @input"
			set childAuxFile to text 9 thru -2 of a_paragraph
			set_base_path(an_auxdata's aux_file()'s posix_path()) of PathConverter
			set theAuxFile to absolute_path of PathConverter for childAuxFile
			set theAuxFile to (POSIX file theAuxFile) as alias
			set a_texdoc to TeXDocController's make_with(theAuxFile, an_auxdata's text_encoding())
			set childAuxObj to auxdata_for_texdoc(a_texdoc)
			--set childAuxObj to findAuxObj(theAuxFile, true)
			if childAuxObj is not missing value then
				parse_aux_file(childAuxObj)
				addChildAuxObj(childAuxObj) of an_auxdata
			end if
			--log "end @input"
		end if
		--log "end loop"
	end repeat
	--log "end of parse_aux_file"
end parse_aux_file

on find_labels_from_doc(an_auxdata, force_flag)
	-- log "start find_labels_from_doc"
	set doc_content to EditorClient's document_content()
	
	set labelCommand to _backslash & "label"
	--log doc_content
	
	set a_xlist to XList's make_with(get every paragraph of doc_content)
	if (not force_flag) and ((an_auxdata's tex_file() is missing value) or (not an_auxdata's is_texfile_updated())) then
		--log "document is not updated"
		if (a_xlist's count_items()) is (an_auxdata's document_size()) then
			--log "document size is same"
			return false
		end if
		--	else
		--		log "document is updated"
	end if
	
	an_auxdata's clear_labels_from_doc()
	repeat while (a_xlist's has_next())
		set a_paragraph to a_xlist's next()
		--log a_paragraph
		if ((length of a_paragraph) > 1) and (a_paragraph does not start with "%") then
			repeat while (a_paragraph contains labelCommand)
				set pos0 to offset of labelCommand in a_paragraph
				set a_paragraph to text pos0 thru -1 of a_paragraph
				set pos1 to offset of "{" in a_paragraph
				if pos1 is 0 then exit repeat
				set pos2 to offset of "}" in a_paragraph
				if pos2 is 0 then exit repeat
				set a_label to text (pos1 + 1) thru (pos2 - 1) of a_paragraph
				if not an_auxdata's has_label(a_label) then
					--log ("add label : " & a_label)
					an_auxdata's addLabelFromDoc(a_label)
				end if
				try
					set a_paragraph to text (pos2 + 1) thru -1 of a_paragraph
				on error
					exit repeat
				end try
			end repeat
		end if
	end repeat
	an_auxdata's update_checked_time()
	an_auxdata's set_document_size(a_xlist's count_items())
	--log "end find_labels_from_doc"
	return true
end find_labels_from_doc

on rebuild_labels_from_aux(a_texdoc)
	--log "start rebuild_labels_from_aux"
	set an_auxdata to auxdata_for_texdoc(a_texdoc)
	--log "after auxdata_for_texdoc in rebuild_labels_from_aux"
	if not (check_auxfile of an_auxdata with display_error) then
		--log "check_auxfile is false"
		return
	end if
	parse_aux_file(an_auxdata)
	clear_labels_from_doc() of an_auxdata
	append_to_outline for an_auxdata below my _label_data_source
	--log "end of rebuild_labels_from_aux"
end rebuild_labels_from_aux
