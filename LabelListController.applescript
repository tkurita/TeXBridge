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

property auxObjArray : missing value
property labelDataSource : missing value
property unsavedAuxObj : missing value
property outlineView : missing value

property ignoringErrors : {1230, 1500}

on initialize(theDataSource)
	set auxObjArray to make XDict
	set labelDataSource to theDataSource
	tell labelDataSource
		make new data column at the end of the data columns with properties {name:"label"}
		make new data column at the end of the data columns with properties {name:"reference"}
	end tell
end initialize

on watchmi given force_reloading:force_flag
	--log "start watchmi in LabelListController"
	try
		set an_auxdata to findAuxObjFromDoc()
	on error msg number errno
		if errno is in {1230, 1500} then
			-- 1230 : ParentFile is invalid.
			-- 1500 : Unsupported File.
			return
		else
			error "Fail to findAuxObjFromDoc in watchmi of LabelListController." & return & msg number errno
		end if
	end try
	
	if an_auxdata is missing value then
		return
	end if
	
	if an_auxdata's data_item() is missing value then
		--log "no data item"
		if an_auxdata's aux_file() is not missing value then
			parseAuxFile(an_auxdata)
		end if
		findLabelsFromDocument(an_auxdata, force_flag)
		if an_auxdata's has_parent() then
			--log "has ParentFile"
			set a_parentdoc to TeXDocController's make_with(an_auxdata's tex_file(), an_auxdata's text_encoding())
			set a_parentaux to auxdata_for_texdoc(a_parentdoc)
			if a_parentaux's data_item() is missing value then
				if (check_auxfile() of a_parentaux) then
					parseAuxFile(a_parentaux)
				end if
			end if
			appendToOutline for a_parentaux below labelDataSource
			an_auxdata's expandDataItem()
		else
			--log "no ParentFile"
			--findLabelsFromDocument(an_auxdata)
			appendToOutline for an_auxdata below labelDataSource
		end if
		
		
	else
		--log "before findLabelsFromDocument"
		if findLabelsFromDocument(an_auxdata, force_flag) then
			--log "before updateLabelsFromDoc"
			updateLabelsFromDoc() of an_auxdata
		else
			--log "skip updateLabelsFromDoc"
		end if
		
	end if
	--log "end of watchmi"
end watchmi

on findAuxObjFromDoc()
	--log "start findAuxObjFromDoc"
	set a_texdoc to texdoc_for_firstdoc of CompileCenter without showing_message and need_file
	if a_texdoc is missing value then
		return missing value
	end if
	
	if (not a_texdoc's has_file()) then
		return auxdata_for_texdoc(a_texdoc)
	end if
	
	--log "start finding ParentFile"
	set parentFile to missing value
	set ith to 1
	repeat
		set a_paragraph to paragraph_at_index(ith) of EditorClient
		if a_paragraph starts with "%" then
			if a_paragraph starts with "%ParentFile" then
				try
					set a_file to a_texdoc's resolve_parent(a_paragraph)
				on error msg number errno
					if errno is 1230 then
						RefPanelController's displayAlert(msg)
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
	
	--log "end  findAuxObjFromDoc"
	return auxdata_for_texdoc(a_texdoc)
end findAuxObjFromDoc

on appendToOutline for theAuxObj below parentDataItem
	--log "start appendToOutline"
	if theAuxObj's data_item() is missing value then
		--log "is first append to outline"
		set titleItem to make new data item at end of data items of parentDataItem
		theAuxObj's set_data_item(titleItem)
		set contents of data cell "label" of titleItem to theAuxObj's basename()
	else
		--log "before updateLabels in appendToOutline"
		updateLabels() of theAuxObj
		return
	end if
	
	--log "before repeat in appendToOutline"
	repeat with theLabelRecord in theAuxObj's all_label_records()
		repeat with ith from 1 to length of theLabelRecord
			set theItem to item ith of theLabelRecord
			set theClass to class of theItem
			if theClass is record then
				set theDataItem to make new data item at end of data items of titleItem
				set contents of data cell "label" of theDataItem to |label| of theItem
				set contents of data cell "reference" of theDataItem to |reference| of theItem
			else if theClass is script then
				appendToOutline for theItem below titleItem
			end if
		end repeat
	end repeat
	--log "before expandDataItem"
	expandDataItem() of theAuxObj
	--log "end appndToOutline"
end appendToOutline

on auxdata_for_texdoc(a_texdoc)
	--log "start auxdata_for_texdoc"
	if a_texdoc's has_file() then
		--log "file is saved"
		set a_key to a_texdoc's no_suffix_target_path()
		--log "auxdata key: " & a_key
		set an_auxdata to auxObjArray's value_for_key(a_key)
		if an_auxdata is missing value then
			--log "new auxdata will be registered"
			set an_auxdata to AuxData's make_with_texdoc(a_texdoc)
			auxObjArray's set_value(a_key, an_auxdata)
		else
			an_auxdata's set_texdoc(a_texdoc) -- update for text encoding
		end if
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

on parseAuxFile(theAuxObj)
	--log "start parseAuxFile"
	set theContents to read_aux_file() of theAuxObj
	--log "before clearLabelsFromAux in parseAuxFile"
	clearLabelsFromAux() of theAuxObj
	--log "start repeat in parseAuxFile"
	set newlabelText to _backslash & "newlabel{"
	set inputText to _backslash & "@input{"
	repeat with ith from 1 to (count paragraph of theContents)
		set theParagraph to paragraph ith of theContents
		--log theParagraph
		if (theParagraph as Unicode text) starts with newlabelText then
			--log "start with newlabelText"
			set theParagraph to text 11 thru -2 of theParagraph
			store_delimiters() of StringEngine
			set theTextItemList to split of StringEngine for theParagraph by "}{"
			restore_delimiters() of StringEngine
			try
				set theRef to ((item -2 of theTextItemList) as string)
			on error
				set theRef to "--"
			end try
			
			set pos2 to (offset of "}{" in theParagraph) as integer
			set theLabel to item 1 of theTextItemList
			
			if not theLabel is "" then
				addLabelFromAux(theLabel, theRef) of theAuxObj
			end if
		else if theParagraph starts with inputText then
			log "start @input"
			set childAuxFile to text 9 thru -2 of theParagraph
			set_base_path(theAuxObj's aux_file()'s posix_path()) of PathConverter
			set theAuxFile to absolute_path of PathConverter for childAuxFile
			set theAuxFile to (POSIX file theAuxFile) as alias
			set a_texdoc to TeXDocController's make_with(theAuxFile, theAuxObj's text_encoding())
			set childAuxObj to auxdata_for_texdoc(a_texdoc)
			--set childAuxObj to findAuxObj(theAuxFile, true)
			if childAuxObj is not missing value then
				parseAuxFile(childAuxObj)
				addChildAuxObj(childAuxObj) of theAuxObj
			end if
			--log "end @input"
		end if
		--log "end loop"
	end repeat
	--log "end of parseAuxFile"
end parseAuxFile

on findLabelsFromDocument(theAuxObj, force_flag)
	--log "start findLabelsFromDocument"
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
	
	clearLabelsFromDoc() of theAuxObj
	repeat while (a_xlist's has_next())
		set theParagraph to a_xlist's next()
		--set theParagraph to paragraph ith of theContents
		--log theParagraph
		if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
			repeat while (theParagraph contains labelCommand)
				set pos0 to offset of labelCommand in theParagraph
				set theParagraph to text pos0 thru -1 of theParagraph
				set pos1 to offset of "{" in theParagraph
				if pos1 is 0 then exit repeat
				set pos2 to offset of "}" in theParagraph
				if pos2 is 0 then exit repeat
				set theLabel to text (pos1 + 1) thru (pos2 - 1) of theParagraph
				--if theLabel is not in labelList of theAuxObj then
				if not theAuxObj's has_label(theLabel) then
					addLabelFromDoc(theLabel) of theAuxObj
				end if
				try
					set theParagraph to text (pos2 + 1) thru -1 of theParagraph
				on error
					exit repeat
				end try
			end repeat
		end if
	end repeat
	theAuxObj's update_checked_time()
	theAuxObj's set_document_size(a_xlist's count_items())
	--log "end findLabelsFromDocument"	
	return true
end findLabelsFromDocument

on rebuildLabelsFromAux(a_texdoc)
	--log "start rebuildLabelsFromAux"
	set an_auxdata to auxdata_for_texdoc(a_texdoc)
	--log "after auxdata_for_texdoc in rebuildLabelsFromAux"
	if not (check_auxfile() of an_auxdata) then
		--log "check_auxfile is false"
		return
	end if
	parseAuxFile(an_auxdata)
	clearLabelsFromDoc() of an_auxdata
	appendToOutline for an_auxdata below labelDataSource
	--log "end of rebuildLabelsFromAux"
end rebuildLabelsFromAux

