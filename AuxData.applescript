global RefPanelController

property outlineView : missing value
property LabelListController : missing value

on all_label_records()
	return {my _labelRecordFromAux, my _labelRecordFromDoc}
end all_label_records

on has_label(a_label)
	return a_label is in my _labelList
end has_label

on set_data_item(an_item)
	set my _dataItemRef to an_item
end set_data_item

on data_item()
	if my _dataItemRef is not missing value then
		if not (exists my _dataItemRef) then
			set my _dataItemRef to missing value
		end if
	end if
	return my _dataItemRef
end data_item

on aux_file()
	return my _auxFileRef
end aux_file

on text_encoding()
	return my _texdoc's text_encoding()
end text_encoding

on has_parent()
	return my _texdoc's has_parent()
end has_parent

on texdoc()
	return my _texdoc
end texdoc

on set_texdoc(a_texdoc)
	set my _texdoc to a_texdoc
end set_texdoc

on is_texfile_updated()
	--log "start is_texfile_updated"
	set a_xfile to tex_file()
	if a_xfile is missing value then
		return false
	end if
	set mod_date to modification date of (a_xfile's re_info())
	--log "end is_texfile_updated"
	return mod_date > my _checkedTime
end is_texfile_updated

on document_size()
	--log "start document_size"
	return my _document_size
end document_size

on set_document_size(doc_size)
	set my _document_size to doc_size
end set_document_size

on update_checked_time()
	set my _checkedTime to current date
end update_checked_time

on tex_file()
	return my _texdoc's file_ref()
end tex_file

on basename()
	if my _texdoc's has_file() then
		--return my _texdoc's basename()
		return my _texdoc's target_file()'s basename()
	else
		return my _texdoc's fileName()
	end if
end basename

on check_auxfile given display_error:alert_flag
	--log "start check_auxfile"
	if my _auxFileRef is missing value then
		--log "_auxFileRef is missing value"
		set tex_source_file to my _texdoc's target_file()
		if tex_source_file is missing value then
			return false
		end if
		set an_auxfile to tex_source_file's change_path_extension("aux")
		if an_auxfile's item_exists() then
			--log "aux file exists"
			set my _auxFileRef to an_auxfile
			return true
		else
			if alert_flag then
				set a_msg to localized string "auxFileIsNotFound"
				display_alert(a_msg) of RefPanelController
			end if
			set my _auxFileRef to missing value
			return false
		end if
	else
		--log "_auxFileRef is not missing value"
		if my _auxFileRef's item_exists() then
			return true
		end if
		set my _auxFileRef to missing value
		return false
	end if
end check_auxfile

on read_aux_file()
	return call method "sniffRead:encodingCandidate:" of (RefPanelController's window_controller()) with parameters {my _auxFileRef's posix_path(), text_encoding()}
end read_aux_file

on add_label_from_aux(a_label, theRef)
	set end of my _labelRecordFromAux to {|label|:a_label, |reference|:theRef}
	set end of my _labelList to a_label
end add_label_from_aux

on add_child_with_auxdata(an_auxdata)
	set end of my _labelRecordFromAux to an_auxdata
end add_child_with_auxdata

on addLabelFromDoc(a_label)
	--log "start addLabelFromDoc"
	set end of my _labelRecordFromDoc to {|label|:a_label, |reference|:"--"}
	--log "end addLabelFromDoc"
end addLabelFromDoc

on is_expanded()
	set a_result to call method "isItemExpanded:" of outlineView with parameter my _dataItemRef
	return a_result is not 0
end is_expanded

on restore_expand_status()
	--log "start restore_expand_status"
	if my _saved_expand_status then
		--log "will expand"
		expand_dataitem()
	end if
	repeat with an_auxdata in my _labelRecordFromAux
		if class of an_auxdata is script then
			an_auxdata's restore_expand_status()
		end if
	end repeat
	--log "end restore_expand_status"
end restore_expand_status

on expand_dataitem()
	--log "start expand_dataitem"
	-- when epanded outline, it seems that width of table column is changed uncorrectly.
	-- fix table column width between before exapand and after expand
	set currentLabelWidth to width of table column "label" of outlineView
	set currentRefWidth to width of table column "reference" of outlineView
	call method "expandItem:" of outlineView with parameter my _dataItemRef
	set width of table column "label" of outlineView to currentLabelWidth
	set width of table column "reference" of outlineView to currentRefWidth
end expand_dataitem

on delete_dataitem()
	--log "start delete_dataitem"
	--log basename()
	set my _saved_expand_status to is_expanded()
	--log "saved expand status : " & my _saved_expand_status
	repeat with an_labelrecord in my _labelRecordFromAux
		if class of an_labelrecord is script then
			an_labelrecord's delete_dataitem()
		end if
	end repeat
	set my _labelRecordFromAux to {}
	set my _labelRecordFromDoc to {}
	--log "end delete_dataitem"
end delete_dataitem

on update_labels()
	--log "start update_labels for " & (aux_file()'s posix_path())
	set nLabelFromAux to length of my _labelRecordFromAux
	set nLabelFromDoc to length of my _labelRecordFromDoc
	set dItemCounter to 1
	set dataitem_counts to count data items of my _dataItemRef
	(*
	--log "dataitem_counts:" & dataitem_counts
	--log "nLabelFromAux:" & nLabelFromAux
	--log my _labelRecordFromAux
	--log "nLabelFromDoc:" & nLabelFromDoc
	--log my _labelRecordFromDoc
	--log "start updating labels from aux"
	*)
	repeat with ith from 1 to nLabelFromAux
		if ith is less than or equal to dataitem_counts then
			set a_dataitem to data item ith of my _dataItemRef
		else
			set a_dataitem to make new data item at end of data items of my _dataItemRef
		end if
		
		set a_labelitem to item ith of my _labelRecordFromAux
		set a_class to class of a_labelitem
		if a_class is record then
			set contents of data cell "label" of a_dataitem to |label| of a_labelitem
			set contents of data cell "reference" of a_dataitem to |reference| of a_labelitem
			if has data items of a_dataitem then
				delete every data item of a_dataitem
			end if
		else if a_class is script then
			a_labelitem's set_data_item(a_dataitem)
			set contents of data cell "label" of a_dataitem to (a_labelitem's basename())
			set contents of data cell "reference" of a_dataitem to ""
			a_labelitem's update_labels()
		end if
	end repeat
	
	--log "start updating labels from doc"
	repeat with ith from 1 to nLabelFromDoc
		set ith_shifted to ith + nLabelFromAux
		if ith_shifted is less than or equal to dataitem_counts then
			set a_dataitem to data item ith_shifted of my _dataItemRef
			if has data items of a_dataitem then
				delete every data item of a_dataitem
			end if
		else
			set a_dataitem to make new data item at end of data items of my _dataItemRef
		end if
		set a_labelitem to item ith of my _labelRecordFromDoc
		set contents of data cell "label" of a_dataitem to |label| of a_labelitem
		set contents of data cell "reference" of a_dataitem to |reference| of a_labelitem
	end repeat
	
	--log "start third repeat"
	set delItemNum to (nLabelFromAux + nLabelFromDoc + 1)
	repeat (dataitem_counts - nLabelFromAux - nLabelFromDoc) times
		delete data item delItemNum of my _dataItemRef
	end repeat
	--log "end of update_labels"
end update_labels

on update_labels_from_doc()
	set dataitem_counts to count data item of my _dataItemRef
	set nLabelFromAux to length of my _labelRecordFromAux
	set nLabelFromDoc to length of my _labelRecordFromDoc
	
	set labCounter to 1
	(*log "before repeat 1"
	--log "dataitem_counts:" & dataitem_counts
	--log "nLabelFromAux:" & nLabelFromAux
	--log "nLabelFromDoc:" & nLabelFromDoc
	*)
	repeat with ith from (nLabelFromAux + 1) to dataitem_counts
		--log "in repeat 1"
		set a_dataitem to data item ith of my _dataItemRef
		
		if labCounter is less than or equal to nLabelFromDoc then
			set theItem to item labCounter of my _labelRecordFromDoc
			set contents of data cell "label" of a_dataitem to |label| of theItem
			set contents of data cell "reference" of a_dataitem to |reference| of theItem
		else
			delete a_dataitem
		end if
		set labCounter to labCounter + 1
	end repeat
	
	--log "before repeat 2"
	repeat with ith from labCounter to nLabelFromDoc
		--log "in repeat 2"
		set theItem to item ith of my _labelRecordFromDoc
		set a_dataitem to make new data item at end of data items of my _dataItemRef
		set contents of data cell "label" of a_dataitem to |label| of theItem
		set contents of data cell "reference" of a_dataitem to |reference| of theItem
	end repeat
end update_labels_from_doc

on clear_labels_from_aux()
	--log "start clear_labels_from_aux"
	repeat with a_labelrecord in my _labelRecordFromAux
		if class of a_labelrecord is script then
			a_labelrecord's delete_dataitem()
		end if
	end repeat
	set my _labelRecordFromAux to {}
	set my _labelList to {}
	--log "end clear_labels_from_aux"
end clear_labels_from_aux

on clear_labels_from_doc_recursively()
	repeat with a_labelrecord in my _labelRecordFromAux
		if class of a_labelrecord is script then
			a_labelrecord's clear_labels_from_doc_recursively()
		end if
	end repeat
	set my _labelRecordFromDoc to {}
end clear_labels_from_doc_recursively

on clear_labels_from_doc()
	--log "start clear_labels_from_doc"
	set my _labelRecordFromDoc to {}
	--log "end clear_labels_from_doc"
end clear_labels_from_doc

on appendLabelsFromDoc()
	repeat with ith from 1 to length of my _labelRecordFromDoc
		set theItem to item ith of my _labelRecordFromDoc
		set a_dataitem to make new data item at end of data items of my _dataItemRef
		set contents of data cell "label" of a_dataitem to |label| of theItem
		set contents of data cell "reference" of a_dataitem to |reference| of theItem
	end repeat
end appendLabelsFromDoc


on make_with_texdoc(a_texdoc)
	--log "start make_with_texdoc in AuxData"
	script AuxData
		property _texdoc : a_texdoc
		property _auxFileRef : missing value
		property _labelRecordFromAux : {}
		property _labelRecordFromDoc : {}
		property _labelList : {}
		property _dataItemRef : missing value
		property _checkedTime : current date
		property _document_size : 0
		property _saved_expand_status : true
	end script
	
	if a_texdoc's has_file() then
		--log "auxdate for " & a_texdoc's target_file()'s posix_path()
		set an_aux_file to a_texdoc's target_file()'s change_path_extension("aux")
		--log "aux file : " & an_aux_file's posix_path()
		if an_aux_file's item_exists() then
			--log "aux file exists"
			set AuxData's _auxFileRef to an_aux_file
		end if
	else
		--log "texdoc does not have file."
	end if
	return AuxData
end make_with_texdoc
