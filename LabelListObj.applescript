global _backslash

global XDict
global StringEngine
global PathConverter
global PathAnalyzer
global XList

global RefPanelController
global EditorClient
global TexDocObj
global AuxData
global TeXCompileObj

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

on watchmi()
	--log "start watchmi in LabelListObj"
	try
		set an_auxdata to findAuxObjFromDoc()
	on error errMsg number errNum
		if errNum is in {1230, 1500} then
			-- 1230 : ParentFile is invalid.
			-- 1500 : Unsupported File.
			return
		else
			error "Fail to findAuxObjFromDoc in watchmi of LabelListObj." & return & errMsg number errNum
		end if
	end try
	
	if an_auxdata is missing value then
		return
	end if
	
	--set theAuxObj to targetAuxObj of resultRecord
	
	if an_auxdata's data_item() is missing value then
		--log "no data item"
		if an_auxdata's aux_file() is not missing value then
			parseAuxFile(an_auxdata)
		end if
		findLabelsFromDocument(an_auxdata)
		if an_auxdata's has_parent() then
			--log "has ParentFile"
			--set auxObjofDoc to findAuxObj(tex_file of resultRecord, is_saved of resultRecord)
			
			set a_parentdoc to TexDocObj's make_with(an_auxdata's tex_file(), an_auxdata's text_encoding())
			set a_parentaux to auxdata_for_texdoc(a_parentdoc)
			if a_parentaux's data_item() is missing value then
				if (check_auxfile() of a_parentaux) then
					parseAuxFile(a_parentaux)
				end if
			end if
			--findLabelsFromDocument(theAuxObj)
			--set auxObjofDoc to auxdata_for_texdoc(a_parentdoc)
			--findLabelsFromDocument(auxObjofDoc)
			--appendToOutline for auxObjofDoc below labelDataSource
			appendToOutline for a_parentaux below labelDataSource
			an_auxdata's expandDataItem()
		else
			--log "no ParentFile"
			--findLabelsFromDocument(an_auxdata)
			appendToOutline for an_auxdata below labelDataSource
		end if
		
		
	else
		(*
		if an_auxdata's has_parent() then
			--set theAuxObj to findAuxObj(tex_file of resultRecord, is_saved of resultRecord)
			set a_parentdoc to TexDocObj's make_with(an_auxdata's tex_file(), an_auxdata's text_encoding())
			set an_auxdata to auxdata_for_texdoc(a_parentdoc)
			--set theAuxObj to findAuxObj(resultRecord)
		end if
		*)
		--log "before findLabelsFromDocument"
		if findLabelsFromDocument(an_auxdata) then
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
	set a_texdoc to texdoc_for_firstdoc of TeXCompileObj without showing_message and need_file
	if a_texdoc is missing value then
		return missing value
	end if
	(*
	if EditorClient's exists_document() then
		set a_tex_file to EditorClient's document_file_as_alias()
		if (EditorClient's document_mode() is not "TEX") then
			return missing value
		end if
	else
		return missing value
	end if
	
	
	set resultRecord to {hasParentFile:false, targetAuxObj:missing value, tex_file:missing value, is_saved:false, text_encoding:missing value}
	--log "after getting mi file in findAuxObjFromDoc"
	
	if a_tex_file is not missing value then
		set tex_file of resultRecord to a_tex_file
		set is_saved of resultRecord to true
		set text_encoding of resultRecord to EditorClient's text_encoding()
	else
		set tex_file of resultRecord to EditorClient's document_name()
		set is_saved of resultRecord to false
		set targetAuxObj of resultRecord to findAuxObj(resultRecord)
		return resultRecord
	end if
	--log "after checking mi file status"
	*)
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
	--repeat with theLabelRecord in {labelRecordFromAux of theAuxObj, labelRecordFromDoc of theAuxObj}
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
		(*
		set pathRecord to do(file_ref) of PathAnalyzer
		set nameWithSuffix to name of pathRecord
		if nameWithSuffix ends with ".tex" then
			set theBaseName to text 1 thru -5 of nameWithSuffix
			set theTexFileRef to file_ref
			try
				set theAuxFileRef to ((folderReference of pathRecord as Unicode text) & theBaseName & ".aux") as alias
			on error
				--log "aux file is not found."
				set theAuxFileRef to missing value
			end try
		else if nameWithSuffix ends with ".aux" then
			set theBaseName to text 1 thru -5 of nameWithSuffix
			set theAuxFileRef to file_ref
			set theTexFileRef to missing value
		else
			--log "unknow suffix"
			--error "Unsupported File." number 1500
			set theBaseName to nameWithSuffix
			set theTexFileRef to file_ref
			try
				set theAuxFileRef to ((folderReference of pathRecord as Unicode text) & theBaseName & ".aux") as alias
			on error
				--log "aux file is not found."
				set theAuxFileRef to missing value
			end try
		end if
		
		set auxObjKey to (folderReference of pathRecord as Unicode text) & theBaseName
		*)
		--set a_key to a_texdoc's no_suffix_posix_path()
		set a_key to a_texdoc's no_suffix_target_path()
		--log "auxdata key: " & a_key
		set an_auxdata to auxObjArray's value_for_key(a_key)
		if an_auxdata is missing value then
			--log "new auxdata will be registered"
			--set an_auxdata to newAuxObj(theTexFileRef, theAuxFileRef, theBaseName, is_saved, text_encoding of source_info)
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
		--set unsavedAuxObj to newAuxObj(missing value, missing value, file_ref, is_saved, text_encoding of source_info)
		set an_auxdata to AuxData's make_with_texdoc(a_texdoc)
		--set theAuxObj to unsavedAuxObj
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
			set a_texdoc to TexDocObj's make_with(theAuxFile, theAuxObj's text_encoding())
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

on findLabelsFromDocument(theAuxObj)
	--log "start findLabelsFromDocument"
	set theContents to EditorClient's document_content()
	
	set labelCommand to _backslash & "label"
	--log "before repeat"
	
	set a_xlist to XList's make_with(get every paragraph of theContents)
	if not is_texfile_updated() of theAuxObj then
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
	--set source_info to {hasParentFile:false, targetAuxObj:missing value, tex_file:a_tex_source's file_ref()'s as_alias(), is_saved:true, text_encoding:a_tex_source's text_encoding()}
	--set theAuxObj to findAuxObj(source_info)
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

