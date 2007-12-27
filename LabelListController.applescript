global _backslash

global XDict
global StringEngine
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
property StringEngine : load script file (LibraryFolder & "StringEngine.scpt")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer.scpt")
property PathConverter : load script file (LibraryFolder & "PathConverter.scpt")
*)

property _aux_data_dict : missing value
property labelDataSource : missing value
property unsavedAuxObj : missing value
property outlineView : missing value

property ignoringErrors : {1230, 1500}

on initialize(theDataSource)
	set my _aux_data_dict to make XDict
	set labelDataSource to theDataSource
	tell labelDataSource
		make new data column at the end of the data columns with properties {name:"label"}
		make new data column at the end of the data columns with properties {name:"reference"}
	end tell
end initialize

on watchmi given force_reloading:force_flag
	--log "start watchmi in LabelListController"
	try
		set an_auxdata to find_auxdata_from_doc()
	on error msg number errno
		if errno is in {1230, 1500} then
			-- 1230 : ParentFile is invalid.
			-- 1500 : Unsupported File.
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
				if (check_auxfile() of a_parentaux) then
					parse_aux_file(a_parentaux)
				end if
			end if
			append_to_outline for a_parentaux below labelDataSource
			an_auxdata's expandDataItem()
		else
			--log "no ParentFile"
			--find_labels_from_doc(an_auxdata)
			append_to_outline for an_auxdata below labelDataSource
		end if
		
		
	else
		--log "before find_labels_from_doc"
		if find_labels_from_doc(an_auxdata, force_flag) then
			--log "before update_labels_from_doc"
			update_labels_from_doc() of an_auxdata
		else
			--log "skip update_labels_from_doc"
		end if
		
	end if
	--log "end of watchmi"
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

on append_to_outline for theAuxObj below parentDataItem
	--log "start append_to_outline"
	if theAuxObj's data_item() is missing value then
		--log "is first append to outline"
		set titleItem to make new data item at end of data items of parentDataItem
		theAuxObj's set_data_item(titleItem)
		set contents of data cell "label" of titleItem to theAuxObj's basename()
	else
		--log "before updateLabels in append_to_outline"
		updateLabels() of theAuxObj
		return
	end if
	
	--log "before repeat in append_to_outline"
	repeat with theLabelRecord in theAuxObj's all_label_records()
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
	--log "before expandDataItem"
	expandDataItem() of theAuxObj
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
		if unsavedAuxObj is not missing value then
			deleteDataItem() of unsavedAuxObj
		end if
		set an_auxdata to AuxData's make_with_texdoc(a_texdoc)
	end if
	
	--log "end auxdata_for_texdoc"
	return an_auxdata
end auxdata_for_texdoc

on parse_aux_file(theAuxObj)
	--log "start parse_aux_file"
	set theContents to read_aux_file() of theAuxObj
	--log "before clearLabelsFromAux in parse_aux_file"
	clearLabelsFromAux() of theAuxObj
	--log "start repeat in parse_aux_file"
	set newlabelText to _backslash & "newlabel{"
	set inputText to _backslash & "@input{"
	repeat with ith from 1 to (count paragraph of theContents)
		set a_paragraph to paragraph ith of theContents
		--log a_paragraph
		if (a_paragraph as Unicode text) starts with newlabelText then
			--log "start with newlabelText"
			set a_paragraph to text 11 thru -2 of a_paragraph
			store_delimiters() of StringEngine
			set theTextItemList to split of StringEngine for a_paragraph by "}{"
			restore_delimiters() of StringEngine
			try
				set theRef to ((item -2 of theTextItemList) as string)
			on error
				set theRef to "--"
			end try
			
			set pos2 to (offset of "}{" in a_paragraph) as integer
			set theLabel to item 1 of theTextItemList
			
			if not theLabel is "" then
				addLabelFromAux(theLabel, theRef) of theAuxObj
			end if
		else if a_paragraph starts with inputText then
			--log "start @input"
			set childAuxFile to text 9 thru -2 of a_paragraph
			set_base_path(theAuxObj's aux_file()'s posix_path()) of PathConverter
			set theAuxFile to absolute_path of PathConverter for childAuxFile
			set theAuxFile to (POSIX file theAuxFile) as alias
			set a_texdoc to TeXDocController's make_with(theAuxFile, theAuxObj's text_encoding())
			set childAuxObj to auxdata_for_texdoc(a_texdoc)
			--set childAuxObj to findAuxObj(theAuxFile, true)
			if childAuxObj is not missing value then
				parse_aux_file(childAuxObj)
				addChildAuxObj(childAuxObj) of theAuxObj
			end if
			--log "end @input"
		end if
		--log "end loop"
	end repeat
	--log "end of parse_aux_file"
end parse_aux_file

on find_labels_from_doc(theAuxObj, force_flag)
	--log "start find_labels_from_doc"
	set theContents to EditorClient's document_content()
	
	set labelCommand to _backslash & "label"
	--log "before repeat"
	
	set a_xlist to XList's make_with(get every paragraph of theContents)
	if (not force_flag) and (not is_texfile_updated() of theAuxObj) then
		--log "document is not updated"
		if (a_xlist's count_items()) is (theAuxObj's document_size()) then
			--log "document size is same"
			return false
		end if
		--	else
		--		log "document is updated"
	end if
	
	clear_labels_from_doc() of theAuxObj
	repeat while (a_xlist's has_next())
		set a_paragraph to a_xlist's next()
		--set a_paragraph to paragraph ith of theContents
		--log a_paragraph
		if ((length of a_paragraph) > 1) and (a_paragraph does not start with "%") then
			repeat while (a_paragraph contains labelCommand)
				set pos0 to offset of labelCommand in a_paragraph
				set a_paragraph to text pos0 thru -1 of a_paragraph
				set pos1 to offset of "{" in a_paragraph
				if pos1 is 0 then exit repeat
				set pos2 to offset of "}" in a_paragraph
				if pos2 is 0 then exit repeat
				set theLabel to text (pos1 + 1) thru (pos2 - 1) of a_paragraph
				--if theLabel is not in labelList of theAuxObj then
				if not theAuxObj's has_label(theLabel) then
					addLabelFromDoc(theLabel) of theAuxObj
				end if
				try
					set a_paragraph to text (pos2 + 1) thru -1 of a_paragraph
				on error
					exit repeat
				end try
			end repeat
		end if
	end repeat
	theAuxObj's update_checked_time()
	theAuxObj's set_document_size(a_xlist's count_items())
	--log "end find_labels_from_doc"	
	return true
end find_labels_from_doc

on rebuild_labels_from_aux(a_texdoc)
	--log "start rebuild_labels_from_aux"
	set an_auxdata to auxdata_for_texdoc(a_texdoc)
	--log "after auxdata_for_texdoc in rebuild_labels_from_aux"
	if not (check_auxfile() of an_auxdata) then
		--log "check_auxfile is false"
		return
	end if
	parse_aux_file(an_auxdata)
	clear_labels_from_doc() of an_auxdata
	append_to_outline for an_auxdata below labelDataSource
	--log "end of rebuild_labels_from_aux"
end rebuild_labels_from_aux
