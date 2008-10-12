global SheetManager
global Root
global EditorClient
global AuxData

property LabelListController : missing value
property _window_controller : missing value
property _window : missing value
global _backslash

property isWorkedTimer : missing value

on window_controller()
	return my _window_controller
end window_controller

on stop_timer()
	if my _window_controller is not missing value then
		call method "temporaryStopReloadTimer" of my _window_controller
	end if
end stop_timer

on restart_timer()
	if my _window_controller is not missing value then
		call method "restartReloadTimer" of my _window_controller
	end if
end restart_timer

on rebuild_labels_from_aux(a_texdoc)
	if my _window_controller is missing value then
		return
	end if
	
	if visible of my _window then
		rebuild_labels_from_aux(a_texdoc) of LabelListController
	end if
end rebuild_labels_from_aux

on watchmi given force_reloading:force_flag
	--log "start watchmi in RefPanelController"
	watchmi of LabelListController given force_reloading:force_flag
	--log "end watchmi in RefPanelController"
end watchmi
(*
on activateFirstmiWindow()
	set a_file to EditorClient's document_file_as_alias()
	
	if a_file is not missing value then
		(*
		ignoring application responses
			tell application "Finder"
				open a_file using miAppRef
			end tell
		end ignoring
		*)
		--EditorClient's open_with_activating(a_file)
		call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
	else
		ignoring application responses
			activate application "mi"
		end ignoring
	end if
end activateFirstmiWindow
*)

on double_clicked(theObject)
	set selectedData to selected data item of theObject
	set a_label to ((contents of data cell "label" of selectedData) as string)
	set theRef to ((contents of data cell "reference" of selectedData) as string)
	if theRef is "" then
		return
	else
		if (state of button "useeqref" of my _window is 1) then
			if (theRef starts with "equation") or (theRef starts with "AMS") then
				set refText to "eqref"
			else if (theRef is "--") and (a_label starts with "eq") then
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
		EditorClient's insert_text("{" & a_label & "}")
	else
		EditorClient's insert_text(refCommand & "{" & a_label & "}")
	end if
	--my activateFirstmiWindow()
	call method "activateAppOfType:" of class "SmartActivate" with parameter "MMKE"
end double_clicked

on initilize()
	--log "start initialize in RefPanelController"
	set my _window_controller to call method "alloc" of class "RefPanelController"
	set my _window_controller to call method "initWithWindowNibName:" of my _window_controller with parameter "ReferencePalette"
	set my _window to call method "window" of my _window_controller
	call method "retain" of my _window
	set LabelListController to Root's import_script("LabelListController")
	initialize(data source "LabelDataSource") of LabelListController
	--set outlineView of LabelListController to outline view "LabelOutline" of scroll view "Scroll" of my _window
	set outlineView of AuxData to outline view "LabelOutline" of scroll view "Scroll" of my _window
	--log "end initialize in RefPanelController"
end initilize

on toggle_visibility()
	if my _window_controller is missing value then
		open_window()
		call method "activateSelf" of class "SmartActivate"
	end if
	
	if (visible of my _window) then
		close my _window
	else
		open_window()
		call method "activateSelf" of class "SmartActivate"
	end if
end toggle_visibility

on open_window()
	--log "start open_window in RefPanelController"
	set is_first to false
	if my _window_controller is missing value then
		initilize()
		set is_first to true
	end if
	--set isWorkingDisplayToggleTimer to call method "isWorkingDisplayToggleTimer" of my _window_controller
	--activate
	call method "showWindow:" of my _window_controller
	--log "after showWIndow"
	--if (is_first or (isWorkingDisplayToggleTimer is 0)) then
	if is_first then
		watchmi of LabelListController without force_reloading
	end if
	--log "end open_window in RefPanelController"
end open_window

on is_opened()
	if my _window_controller is missing value then
		return false
	end if
	set a_result to call method "isOpened" of my _window_controller
	return (a_result is 1)
end is_opened

on display_alert(a_msg)
	display alert a_msg attached to my _window as warning
	(*
	script endOfAlert
		on sheetEnded(theReply)
		end sheetEnded
	end script
	
	addSheetRecord of SheetManager given parentWindow:my my _window, ownerObject:endOfAlert
	*)
end display_alert