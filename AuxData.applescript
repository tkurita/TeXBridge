global RefPanelController
property outlineView : missing value

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
		return my _texdoc's basename()
	else
		return my _texdoc's filename()
	end if
end basename

on check_auxfile given display_error:alert_flag
	--log "start check_auxfile"
	if my _auxFileRef is missing value then
		--log "_auxFileRef is missing value"
		set an_auxfile to tex_file()'s change_path_extension(".aux")
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

on addLabelFromAux(a_label, theRef)
	set end of my _labelRecordFromAux to {|label|:a_label, |reference|:theRef}
	set end of my _labelList to a_label
end addLabelFromAux

on addChildAuxObj(an_auxdata)
	set end of my _labelRecordFromAux to an_auxdata
end addChildAuxObj

on addLabelFromDoc(a_label)
	--log "start addLabelFromDoc"
	set end of my _labelRecordFromDoc to {|label|:a_label, |reference|:"--"}
	--log "end addLabelFromDoc"
end addLabelFromDoc

on is_expanded()
	set a_result to call method "isItemExpanded:" of outlineView with parameter my _dataItemRef
	return a_result is not 0
end is_expanded

on expandDataItem()
	--log "start expandDataItem"
	-- when epanded outline, it seems that width of table column is changed uncorrectly.
	-- fix table column width between before exapand and after expand
	set currentLabelWidth to width of table column "label" of outlineView
	set currentRefWidth to width of table column "reference" of outlineView
	call method "expandItem:" of outlineView with parameter my _dataItemRef
	set width of table column "label" of outlineView to currentLabelWidth
	set width of table column "reference" of outlineView to currentRefWidth
end expandDataItem

on deleteDataItem()
	set my _labelRecordFromAux to {}
	set my _labelRecordFromDoc to {}
	delete my _dataItemRef
end deleteDataItem

on deleteChildDataItem()
	if my _dataItemRef is not missing value then
		set my _labelRecordFromAux to {}
		set my _labelRecordFromDoc to {}
		delete (every data item of my _dataItemRef)
	end if
end deleteChildDataItem

on updateLabels()
	--log "start updateLabels"
	set nDataItem to count data item of my _dataItemRef
	set nLabelFromAux to length of my _labelRecordFromAux
	set nLabelFromDoc to length of my _labelRecordFromDoc
	set dItemCounter to 1
	(*
	log "nDataItem:" & nDataItem
	log "nLabelFromAux:" & nLabelFromAux
	log my _labelRecordFromAux
	log "nLabelFromDoc:" & nLabelFromDoc
	log my _labelRecordFromDoc
	log "start updating   labels from aux"
	*)
	repeat with ith from 1 to nLabelFromAux
		if ith is less than or equal to nDataItem then
			set theDataItem to data item ith of my _dataItemRef
		else
			set theDataItem to make new data item at end of data items of my _dataItemRef
		end if
		
		set theItem to item ith of my _labelRecordFromAux
		set a_class to class of theItem
		if a_class is record then
			set contents of data cell "label" of theDataItem to |label| of theItem
			set contents of data cell "reference" of theDataItem to |reference| of theItem
			if has data items of theDataItem then
				delete every data item of theDataItem
			end if
		else if a_class is script then
			--set my _dataItemRef of theItem to theDataItem
			theItem's set_data_item(theDataItem)
			set contents of data cell "label" of theDataItem to (theItem's basename())
			set contents of data cell "reference" of theDataItem to ""
			theItem's updateLabels()
		end if
	end repeat
	
	--log "start updating labels from doc"
	repeat with ith from 1 to nLabelFromDoc
		set ith_shifted to ith + nLabelFromAux
		if ith_shifted is less than or equal to nDataItem then
			set theDataItem to data item ith_shifted of my _dataItemRef
			if has data items of theDataItem then
				delete every data item of theDataItem
			end if
		else
			set theDataItem to make new data item at end of data items of my _dataItemRef
		end if
		set theItem to item ith of my _labelRecordFromDoc
		set contents of data cell "label" of theDataItem to |label| of theItem
		set contents of data cell "reference" of theDataItem to |reference| of theItem
	end repeat
	
	--log "start third repeat"
	set delItemNum to (nLabelFromAux + nLabelFromDoc + 1)
	repeat (nDataItem - nLabelFromAux - nLabelFromDoc) times
		delete data item delItemNum of my _dataItemRef
	end repeat
	--log "end of updateLabels"
end updateLabels

on update_labels_from_doc()
	set nDataItem to count data item of my _dataItemRef
	set nLabelFromAux to length of my _labelRecordFromAux
	set nLabelFromDoc to length of my _labelRecordFromDoc
	
	set labCounter to 1
	(*log "before repeat 1"
	log "nDataItem:" & nDataItem
	log "nLabelFromAux:" & nLabelFromAux
	log "nLabelFromDoc:" & nLabelFromDoc
	*)
	repeat with ith from (nLabelFromAux + 1) to nDataItem
		--log "in repeat 1"
		set theDataItem to data item ith of my _dataItemRef
		
		if labCounter is less than or equal to nLabelFromDoc then
			set theItem to item labCounter of my _labelRecordFromDoc
			set contents of data cell "label" of theDataItem to |label| of theItem
			set contents of data cell "reference" of theDataItem to |reference| of theItem
		else
			delete theDataItem
		end if
		set labCounter to labCounter + 1
	end repeat
	
	--log "before repeat 2"
	repeat with ith from labCounter to nLabelFromDoc
		--log "in repeat 2"
		set theItem to item ith of my _labelRecordFromDoc
		set theDataItem to make new data item at end of data items of my _dataItemRef
		set contents of data cell "label" of theDataItem to |label| of theItem
		set contents of data cell "reference" of theDataItem to |reference| of theItem
	end repeat
end update_labels_from_doc

on clear_labels_from_aux()
	set my _labelRecordFromAux to {}
	set my _labelList to {}
end clear_labels_from_aux

on clear_labels_from_doc()
	--log "start clear_labels_from_doc"
	repeat with theLabelRecord in my _labelRecordFromAux
		if class of theLabelRecord is script then
			clear_labels_from_doc() of theLabelRecord
		end if
	end repeat
	set my _labelRecordFromDoc to {}
	--log "end clear_labels_from_doc"
end clear_labels_from_doc

on appendLabelsFromDoc()
	repeat with ith from 1 to length of my _labelRecordFromDoc
		set theItem to item ith of my _labelRecordFromDoc
		set theDataItem to make new data item at end of data items of my _dataItemRef
		set contents of data cell "label" of theDataItem to |label| of theItem
		set contents of data cell "reference" of theDataItem to |reference| of theItem
	end repeat
end appendLabelsFromDoc


on make_with_texdoc(a_texdoc)
	script AuxData
		property _texdoc : a_texdoc
		property _auxFileRef : missing value
		property _labelRecordFromAux : {}
		property _labelRecordFromDoc : {}
		property _labelList : {}
		property _dataItemRef : missing value
		property _checkedTime : current date
		property _document_size : missing value
	end script
	
	if a_texdoc's has_file() then
		set an_aux_file to a_texdoc's target_file()'s change_path_extension(".aux")
		if an_aux_file's item_exists() then
			set AuxData's _auxFileRef to an_aux_file
		end if
	end if
	return AuxData
end make_with_texdoc
