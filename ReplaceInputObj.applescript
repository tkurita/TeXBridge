(* Shared Constants *)
global yenmark

(* Shared Libraries *)
global UtilityHandlers
global SettingWindowController
global KeyValueDictionary
global DefaultsManager

(* references to the GUI *)
property internalReplaceOutline : missing value
property userReplaceTable : missing value
property userReplaceDataSource : missing value
property parentView : missing value

(* variables of dictionary *)
property internalReplaceDict : missing value
property dictList : missing value
property userReplaceDict : missing value

(* variables in this script object *)
property preKeyword : missing value
property preReplace : missing value
property userKeywordList : missing value
property numUserKeyword : missing value
property isChangedUserDict : false
property previousDataRow : missing value

on saveUserDict()
	if isChangedUserDict then
		--log "user dict will be saved"
		tell user defaults
			set contents of default entry "ReplaceInput_KeyList" to keyList of userReplaceDict
			set contents of default entry "ReplaceInput_ValueList" to valueList of userReplaceDict
		end tell
		set isChangedUserDict to false
	end if
end saveUserDict

on addToUserDict given keyword:keywordText, replace:replaceText
	--log "start addToUserDict"
	if keywordText is in userKeywordList then
		--log userKeywordList
		set theMessage to getLocalizedString of UtilityHandlers given keyword:"keywordStillDefined", insertTexts:{keywordText}
		displayAlert(theMessage) of SettingWindowController
		return false
	else
		setValue of userReplaceDict given forKey:keywordText, withValue:replaceText
		set end of userKeywordList to keywordText
		set isChangedUserDict to true
		saveUserDict()
		return true
	end if
end addToUserDict

on shouldSelectionChange(theObject)
	--log "start shouldSelectionChange in ReplaceInputObj"
	(*
	set editedRow to edited row of theObject
	
	if editedRow is not 0 then
		return true
	end if
	*)
	
	set selectedData to selected data row of theObject
	
	try
		if selectedData is previousDataRow then
			return true
		end if
		set theKeyword to contents of data cell "keyword" of selectedData
		set theReplace to contents of data cell "replace" of selectedData
	on error
		--log "no previos selection"
		set previousDataRow to missing value
		return true
	end try
	
	if theKeyword is "" then
		set theMessage to localized string "keywordiIsBlank"
		displayAlert(theMessage) of SettingWindowController
		return false
	else if theReplace is "" then
		set theMessage to localized string "replaceIsBlank"
		displayAlert(theMessage) of SettingWindowController
		--log "there are blanked cells"
		return false
	else
		--log "cells are filled"
		if (addToUserDict given keyword:theKeyword, replace:theReplace) then
			set previousDataRow to selectedData
			return true
		else
			return false
		end if
	end if
end shouldSelectionChange

on selectionChanged(theObject)
	--log "start selectionChanged in ReplaceInputObj"
	set theDataRow to selected data row of theObject
	try
		get theDataRow
	on error
		--log "empty selection"
		return
	end try
	
	set preKeyword to contents of data cell "keyword" of theDataRow
	set preReplace to contents of data cell "replace" of theDataRow
	if preKeyword is not "" then
		--log "keyword is not blank"
		set userKeywordList to deleteListItem of UtilityHandlers for preKeyword from userKeywordList
	end if
	--log "end selectionChanged in ReplaceInputObj"
end selectionChanged

on controlClicked(theObject)
	set theName to name of theObject
	if theName is "addReplaceText" then
		--log "called addRelaceText"
		if shouldSelectionChange(userReplaceTable) then
			set theRow to make new data row at the end of the data rows of userReplaceDataSource
			set selected data row of userReplaceTable to theRow
			set first responder of window of userReplaceTable to userReplaceTable
		end if
	else if theName is "removeReplaceText" then
		set selectedDataRow to selected data row of userReplaceTable
		try
			delete selectedDataRow
		on error
			retrun
		end try
		--log preKeyword
		if preKeyword is not "" then
			if removeItem of userReplaceDict given forKey:preKeyword then
				set isChangedUserDict to true
				saveUserDict()
			end if
		end if
	end if
end controlClicked

on initialize()
	if userReplaceDict is missing value then
		set userReplaceDict to makeObj() of KeyValueDictionary
		set keyList of userReplaceDict to readDefaultValueWith("ReplaceInput_KeyList", {}) of DefaultsManager
		set valueList of userReplaceDict to readDefaultValueWith("ReplaceInput_ValueList", {}) of DefaultsManager
	end if
	
	if internalReplaceDict is missing value then
		set internalReplaceDict to loadPlistDictionary("ReplaceDictionary") of UtilityHandlers
		set dictList to call method "allValues" of internalReplaceDict
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
	-- log "end appendDictToOutline"
end appendDictToOutline

on setSettingToWindow(theView)
	--log "start setSettingToWindow in ReplaceInputObj"
	set parentView to theView
	set internalReplaceOutline to outline view "InternalReplaceOutline" of scroll view "InternalReplaceScroll" of theView
	set userReplaceTable to table view "UserReplaceTable" of scroll view "UserReplaceScroll" of theView
	
	initialize()
	--log "success initialize"
	set internalReplaceDataSource to data source of internalReplaceOutline
	set userReplaceDataSource to data source of userReplaceTable
	--log "success get data source"
	
	--log "set internal keywords"
	set categoryList to call method "allKeys" of internalReplaceDict
	repeat with theCategory in categoryList
		set categoryItem to make new data item at end of data items of internalReplaceDataSource
		set categoryText to localized string theCategory
		set contents of data cell "keyword" of categoryItem to categoryText
		set contents of data cell "replace" of categoryItem to ""
		set theDict to getKeyValue of UtilityHandlers for theCategory from internalReplaceDict
		--log "before appendDictToOutline"
		appendDictToOutline for theDict into categoryItem
	end repeat
	
	--log "set user-defined keywords"
	copy keyList of userReplaceDict to userKeywordList
	set numUserKeyword to length of userKeywordList
	
	if numUserKeyword > 0 then
		repeat with ith from 1 to numUserKeyword
			set theKeyword to item ith of userKeywordList
			set replaceText to item ith of valueList of userReplaceDict
			set theDataItem to make new data row at end of data rows of userReplaceDataSource
			set contents of data cell "keyword" of theDataItem to theKeyword
			set contents of data cell "replace" of theDataItem to replaceText
			--log theKeyword & " : " & replaceText
		end repeat
		tell userReplaceTable to update
	end if
	--log "end setSettingToWindow in ReplaceInputObj"
end setSettingToWindow

on findReplaceText(keyText)
	--log "start findReplaceText for " & keyText
	--log "find replaceText from user dictionary"
	set newText to getValue of userReplaceDict given forKey:keyText
	if newText is not missing value then
		--log "replece text is found from userReplaceDict"
		return newText
	end if
	
	--log "find replaceText from internal dictionary"
	repeat with theDict in dictList
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
	
	set targetText to text 1 thru cursorPositionInPar of theLine
	if targetText ends with yenmark then
		return
	end if
	set lastYenPosition to (offsetLastYenmark(targetText))
	set keyText to text (lastYenPosition + 1) thru -1 of targetText
	
	set newText to missing value
	--set newText to getKeyValue of UtilityHandlers for keyText from internalReplaceDict
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

on offsetLastYenmark(theText)
	set theOffset to offset of yenmark in theText
	if theOffset is 0 then
		return theOffset
	else
		set theNextOffset to offsetLastYenmark(text (theOffset + 1) thru -1 of theText)
		return theOffset + theNextOffset
	end if
end offsetLastYenmark

