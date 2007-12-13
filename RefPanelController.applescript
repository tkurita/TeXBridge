global SheetManager
global ScriptImporter
global EditorClient
global AuxData

property LabelListController : missing value
property WindowController : missing value
property targetWindow : missing value
global miAppRef
global _backslash

property isWorkedTimer : missing value

on stopTimer()
	if WindowController is not missing value then
		call method "temporaryStopReloadTimer" of WindowController
	end if
end stopTimer

on restartTimer()
	if WindowController is not missing value then
		call method "restartReloadTimer" of WindowController
	end if
end restartTimer

on rebuildLabelsFromAux(a_texdoc)
	if WindowController is missing value then
		return
	end if
	
	if visible of targetWindow then
		rebuildLabelsFromAux(a_texdoc) of LabelListController
	end if
end rebuildLabelsFromAux

on watchmi given force_reloading:force_flag
	--log "start watchmi in RefPanelController"
	watchmi of LabelListController given force_reloading:force_flag
	--log "end watchmi in RefPanelController"
end watchmi

on activateFirstmiWindow()
	set a_file to EditorClient's document_file_as_alias()
	
	if a_file is not missing value then
		ignoring application responses
			tell application "Finder"
				open a_file using miAppRef
			end tell
		end ignoring
	else
		ignoring application responses
			activate application "mi"
		end ignoring
	end if
end activateFirstmiWindow

on doubleClicked(theObject)
	set selectedData to selected data item of theObject
	set theLabel to ((contents of data cell "label" of selectedData) as string)
	set theRef to ((contents of data cell "reference" of selectedData) as string)
	if theRef is "" then
		return
	else
		if (state of button "useeqref" of targetWindow is 1) then
			if (theRef starts with "equation") or (theRef starts with "AMS") then
				set refText to "eqref"
			else if (theRef is "--") and (theLabel starts with "eq") then
				set refText to "eqref"
			else
				set refText to "ref"
			end if
		else
			set refText to "ref"
		end if
	end if
	
	try
		set selectionRecord to selection_info() of EditorClient
	on error
		return
	end try
	
	set posInLine to cursorInParagraph of selectionRecord
	if (posInLine > 0) then
		set textBeforeCursor to text 1 thru posInLine of currentParagraph of selectionRecord
	else
		set textBeforeCursor to ""
	end if
	set refCommand to _backslash & refText
	if (textBeforeCursor as Unicode text) ends with (refCommand as Unicode text) then
		EditorClient's insert_text("{" & theLabel & "}")
	else
		EditorClient's insert_text(refCommand & "{" & theLabel & "}")
	end if
	my activateFirstmiWindow()
end doubleClicked

on initilize()
	--log "start initialize in RefPanelController"
	set WindowController to call method "alloc" of class "RefPanelController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "ReferencePalette"
	set targetWindow to call method "window" of WindowController
	call method "retain" of targetWindow
	set LabelListController to ScriptImporter's do("LabelListController")
	initialize(data source "LabelDataSource") of LabelListController
	--set outlineView of LabelListController to outline view "LabelOutline" of scroll view "Scroll" of targetWindow
	set outlineView of AuxData to outline view "LabelOutline" of scroll view "Scroll" of targetWindow
	--log "end initialize in RefPanelController"
end initilize

on toggle_visibility()
	if WindowController is missing value then
		open_window()
		call method "activateSelf" of class "SmartActivate"
	end if
	
	if (visible of targetWindow) then
		close targetWindow
	else
		open_window()
		call method "activateSelf" of class "SmartActivate"
	end if
end toggle_visibility

on open_window()
	--log "start open_window in RefPanelController"
	set is_first to false
	if WindowController is missing value then
		initilize()
		set is_first to true
	end if
	--set isWorkingDisplayToggleTimer to call method "isWorkingDisplayToggleTimer" of WindowController
	--activate
	call method "showWindow:" of WindowController
	--log "after showWIndow"
	--if (is_first or (isWorkingDisplayToggleTimer is 0)) then
	if is_first then
		watchmi of LabelListController without force_reloading
	end if
	--log "end open_window in RefPanelController"
end open_window

on isOpened()
	if WindowController is missing value then
		return false
	end if
	set theResult to call method "isOpened" of WindowController
	return (theResult is 1)
end isOpened

on displayAlert(theMessage)
	display alert theMessage attached to targetWindow as warning
	(*
	script endOfAlert
		on sheetEnded(theReply)
		end sheetEnded
	end script
	
	addSheetRecord of SheetManager given parentWindow:my targetWindow, ownerObject:endOfAlert
	*)
end displayAlert