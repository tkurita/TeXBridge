global SheetManager
global ScriptImporter

property LabelListObj : missing value
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

on rebuildLabelsFromAux(theTexDocObj)
	if WindowController is missing value then
		return
	end if
	
	if visible of targetWindow then
		set theTexFileRef to texFileRef of theTexDocObj
		rebuildLabelsFromAux(theTexFileRef) of LabelListObj
	end if
end rebuildLabelsFromAux

on watchmi()
	--log "start watchmi in RefPanelController"
	watchmi() of LabelListObj
	--log "end watchmi in RefPanelController"
end watchmi

on activateFirstmiWindow()
	tell application "mi"
		try
			set theFile to (file of document 1) as alias
		on error
			set theFile to missing value
		end try
	end tell
	
	if theFile is not missing value then
		ignoring application responses
			tell application "Finder"
				open theFile using miAppRef
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
	
	tell application "mi"
		if exists front document then
			tell front document
				--set parPosition to index of paragraph 1 of selection object 1
				set cursorPosition to (index of insertion point 1 of selection object 1)
				set linePos to index of insertion point 1 of paragraph 1 of selection object 1
				set currentLine to paragraph 1 of selection object 1
			end tell
		else
			return
		end if
	end tell
	set curPosInLine to cursorPosition - linePos
	set textBeforeCursor to text 1 thru (cursorPosition - linePos) of currentLine
	set refCommand to _backslash & refText
	if (textBeforeCursor as Unicode text) ends with (refCommand as Unicode text) then
		tell application "mi"
			tell front document
				set selection object 1 to "{" & theLabel & "}"
			end tell
		end tell
	else
		tell application "mi"
			tell front document
				set selection object 1 to refCommand & "{" & theLabel & "}"
			end tell
		end tell
	end if
	my activateFirstmiWindow()
end doubleClicked

on initilize()
	--set miAppRef to path to application "mi" as alias
	set WindowController to call method "alloc" of class "RefPanelController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "ReferencePalette"
	set targetWindow to call method "window" of WindowController
	call method "retain" of targetWindow
	set LabelListObj to ScriptImpoter's do("LabelListObj")
	initialize(data source "LabelDataSource") of LabelListObj
	set outlineView of LabelListObj to outline view "LabelOutline" of scroll view "Scroll" of targetWindow
end initilize

on openWindow()
	set isFirst to false
	if WindowController is missing value then
		initilize()
		set isFirst to true
	end if
	--set isWorkingDisplayToggleTimer to call method "isWorkingDisplayToggleTimer" of WindowController
	--activate
	call method "showWindow:" of WindowController
	--if (isFirst or (isWorkingDisplayToggleTimer is 0)) then
	if isFirst then
		watchmi() of LabelListObj
	end if
end openWindow

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