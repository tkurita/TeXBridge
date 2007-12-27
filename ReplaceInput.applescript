(* Shared Constants *)
global _backslash

(* Shared Libraries *)
global UtilityHandlers
global SettingWindowController
global XDict
global DefaultsManager

(* references to the GUI *)
property _internalReplaceOutline : missing value
property _userReplaceTable : missing value
property _userReplaceDataSource : missing value
property _removeButton : missing value
--property parentView : missing value

(* variables of dictionary *)
property _internalReplaceDict : missing value
property _dict_set : missing value
property _user_replace_dict : missing value

(* variables in this script object *)
property _pre_keyword : missing value
property _pre_replace : missing value
property _is_changed_userdict : false
property _pre_data_row : missing value

on set_gui_element(an_object)
	--log "start set_gui_element"
	set a_name to name of an_object
	if a_name is "RemoveReplaceText" then
		set my _removeButton to an_object
	else if a_name is "InternalReplaceOutline" then
		set my _internalReplaceOutline to an_object
	else if a_name is "UserReplaceTable" then
		set my _userReplaceTable to an_object
		set my _userReplaceDataSource to data source of my _userReplaceTable
	end if
end set_gui_element

on saveUserDict()
	if my _is_changed_userdict then
		--log "user dict will be saved"
		tell user defaults
			set contents of default entry "ReplaceInput_KeyList" to (my _user_replace_dict's all_keys())
			set contents of default entry "ReplaceInput_ValueList" to (my _user_replace_dict's all_values())
		end tell
		set my _is_changed_userdict to false
	end if
end saveUserDict

on addToUserDict given keyword:a_keyword, replace:replaceText
	--log "start addToUserDict"
	(*
	considering case
		set is_defined to keywordText is in my _userKeywordList
	end considering
	*)
	
	if (my _pre_keyword is not a_keyword) and (my _user_replace_dict's has_key(a_keyword)) then
		--log my _userKeywordList
		set a_msg to UtilityHandlers's localized_string("keywordStillDefined", {a_keyword})
		display_alert(a_msg) of SettingWindowController
		return false
	else
		my _user_replace_dict's remove_for_key(my _pre_keyword)
	end if
	my _user_replace_dict's set_value(a_keyword, replaceText)
	set my _is_changed_userdict to true
	saveUserDict()
	return true
end addToUserDict

on cell_value_changed(theObject, theRow, tableColumn, theValue)
	--log "start cell_value_changed"
	set current_row to data row theRow of data source of theObject
	set a_keyword to contents of data cell "keyword" of current_row
	set a_replace to contents of data cell "replace" of current_row
	--log a_keyword
	--log a_replace
	if (a_keyword is "") or (a_replace is "") then
		return true
	end if
	
	if (my _pre_keyword is a_keyword) and (my _pre_replace is a_replace) then
		return true
	end if
	
	if (addToUserDict given keyword:a_keyword, replace:a_replace) then
		set my _pre_keyword to a_keyword
		set my _pre_replace to a_replace
		return true
	else
		set contents of data cell "keyword" of current_row to my _pre_keyword
		return false
	end if
	
end cell_value_changed

on should_selection_change(theObject)
	--log "start should_selection_change in ReplaceInput"
	
	set selected_data_row to selected data row of theObject
	
	try
		if selected_data_row is my _pre_data_row then
			return true
		end if
		set a_keyword to contents of data cell "keyword" of selected_data_row
		set a_replace to contents of data cell "replace" of selected_data_row
	on error
		--log "no previos selection"
		set my _pre_data_row to missing value
		return true
	end try
	
	if a_keyword is "" then
		set a_msg to localized string "keywordiIsBlank"
		display_alert(a_msg) of SettingWindowController
		return false
	else if a_replace is "" then
		set a_msg to localized string "replaceIsBlank"
		display_alert(a_msg) of SettingWindowController
		--log "there are blanked cells"
		return false
	else
		--log "cells are filled"
		set my _pre_data_row to selected_data_row
		return true
	end if
end should_selection_change

on selection_changed(theObject)
	--log "start selection_changed in ReplaceInput"
	set a_data_row to selected data row of theObject
	try
		get a_data_row
	on error
		--log "empty selection"
		return
	end try
	
	set my _pre_keyword to contents of data cell "keyword" of a_data_row
	set my _pre_replace to contents of data cell "replace" of a_data_row
	set enabled of my _removeButton to true
	--log "end selection_changed in ReplaceInput"
end selection_changed

on control_clicked(theObject)
	set a_name to name of theObject
	if a_name is "addReplaceText" then
		--log "called addRelaceText"
		if should_selection_change(my _userReplaceTable) then
			set theRow to make new data row at the end of the data rows of my _userReplaceDataSource
			set selected data row of my _userReplaceTable to theRow
			set first responder of window of my _userReplaceTable to my _userReplaceTable
		end if
	else if a_name is "removeReplaceText" then
		set selectedDataRow to selected data row of my _userReplaceTable
		try
			delete selectedDataRow
		on error
			return
		end try
		--log my _pre_keyword
		if my _pre_keyword is not "" then
			if my _user_replace_dict's remove_for_key(my _pre_keyword) then
				--log "success removing keyword"
				set my _is_changed_userdict to true
				saveUserDict()
				selection_changed(my _userReplaceTable)
			end if
		end if
	end if
end control_clicked

on initialize()
	if my _user_replace_dict is missing value then
		set key_list to value_with_default("ReplaceInput_KeyList", {}) of DefaultsManager
		set value_list to value_with_default("ReplaceInput_ValueList", {}) of DefaultsManager
		set my _user_replace_dict to XDict's make_with_lists(key_list, value_list)
	end if
	
	if my _internalReplaceDict is missing value then
		set my _internalReplaceDict to loadPlistDictionary("ReplaceDictionary") of UtilityHandlers
		set my _dict_set to call method "allValues" of my _internalReplaceDict
	end if
end initialize

on appendDictToOutline for theDict into parentDataItem
	--log "start appendDictToOutline"
	set keywordList to call method "allKeys" of theDict
	set dataRecord to {}
	--log "before repeat"
	repeat with ith from 1 to count keywordList
		set theKeyword to item ith of keywordList
		set replaceText to getKeyValue of UtilityHandlers for theKeyword from theDict
		set theDataItem to make new data item at end of data items of parentDataItem
		set contents of data cell "keyword" of theDataItem to theKeyword
		set contents of data cell "replace" of theDataItem to replaceText
	end repeat
	--log "end appendDictToOutline"
end appendDictToOutline

on setSettingToWindow(a_view)
	--log "start setSettingToWindow in ReplaceInput"
	
	initialize()
	--log "success initialize"
	set internalReplaceDataSource to data source of my _internalReplaceOutline
	--log "success get data source"
	
	--log "set internal keywords"
	set categoryList to call method "allKeys" of my _internalReplaceDict
	--log "after allkeys"
	repeat with theCategory in categoryList
		set categoryItem to make new data item at end of data items of internalReplaceDataSource
		set categoryText to localized string theCategory
		set contents of data cell "keyword" of categoryItem to categoryText
		set contents of data cell "replace" of categoryItem to ""
		set theDict to getKeyValue of UtilityHandlers for theCategory from my _internalReplaceDict
		--log "before appendDictToOutline"
		appendDictToOutline for theDict into categoryItem
	end repeat
	
	--log "set user-defined keywords"
	if my _user_replace_dict's count_keys() > 0 then
		script setup_data_cell
			on do(a_pair)
				set a_data_item to make new data row at end of data rows of my _userReplaceDataSource
				tell a_data_item
					set contents of data cell "keyword" to item 1 of a_pair
					set contents of data cell "replace" to item 2 of a_pair
				end tell
				return true
			end do
		end script
		--log "will before set data cells"
		my _user_replace_dict's each(setup_data_cell)
		tell my _userReplaceTable to update
	end if
	--log "end setSettingToWindow in ReplaceInput"
end setSettingToWindow

on findReplaceText(keyText)
	--log "start findReplaceText for " & keyText
	--log "find replaceText from user dictionary"
	try
		return my _user_replace_dict's value_for_key(keyText)
	on error number 900
	end try
	(*
	if newText is not missing value then
		--log "replece text is found from userReplaceDict"
		return newText
	end if
	*)
	
	--log "find replaceText from internal dictionary"
	repeat with theDict in my _dict_set
		set newText to getKeyValue of UtilityHandlers for keyText from theDict
		try
			get newText
			return newText
		end try
	end repeat
	
	-- replace text is not found associated for key value
	error "replace text is not found." number 1270
end findReplaceText

on do()
	initialize()
	tell application "mi"
		tell first document
			set cursorPosition to (index of insertion point 1 of selection object 1)
			--set nChar to count character
			if cursorPosition is 1 then -- cursor is  at beginning of document
				error "beginning of document."
			end if
			set lineIndex to index of paragraph 1 of selection object 1
			set linePos to index of insertion point 1 of paragraph lineIndex
			set theLine to paragraph lineIndex
		end tell
	end tell
	set cursorPositionInPar to cursorPosition - linePos
	if cursorPositionInPar is 0 then -- cursor is in line head
		return
	end if
	
	set targetText to text 1 thru cursorPositionInPar of theLine
	if targetText ends with _backslash then
		return
	end if
	set lastYenPosition to (offsetLastBackslash(targetText))
	set keyText to text (lastYenPosition + 1) thru -1 of targetText
	
	set newText to missing value
	--set newText to getKeyValue of UtilityHandlers for keyText from my _internalReplaceDict
	try
		set newText to findReplaceText(keyText)
	on error number 1270
		return
	end try
	
	set fText to text 1 thru lastYenPosition of theLine
	if length of theLine is cursorPositionInPar then
		set sText to ""
	else
		set sText to text (cursorPositionInPar + 1) thru -1 of theLine
	end if
	set newLine to fText & newText & sText
	tell application "mi"
		tell first document
			set paragraph lineIndex to newLine
			--set paragraph 1 of selection object 1 to newLine
			select insertion point (cursorPosition - ((length of keyText) - (length of newText)))
		end tell
	end tell
end do

on offsetLastBackslash(theText)
	set theOffset to offset of _backslash in theText
	if theOffset is 0 then
		return theOffset
	else
		set theNextOffset to offsetLastBackslash(text (theOffset + 1) thru -1 of theText)
		return theOffset + theNextOffset
	end if
end offsetLastBackslash

