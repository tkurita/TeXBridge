global DefaultsManager
global UtilityHandlers
global SheetManager

property LabelListObj : missing value
property WindowController : missing value
property targetWindow : missing value
--property miAppRef : missing value
global miAppRef
global yenmark

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
	if theRef is not "" then
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
		
		tell application "mi"
			if exists document 1 then
				tell document 1
					set selection object 1 to yenmark & refText & "{" & theLabel & "}"
				end tell
				my activateFirstmiWindow()
			end if
		end tell
	end if
end doubleClicked

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on initilize()
	--set miAppRef to path to application "mi" as alias
	set WindowController to call method "alloc" of class "RefPanelController"
	set WindowController to call method "initWithWindowNibName:" of WindowController with parameter "ReferencePalette"
	set targetWindow to call method "window" of WindowController
	set LabelListObj to importScript("LabelListObj")
	initialize(data source "LabelDataSource") of LabelListObj
	set outlineView of LabelListObj to outline view "LabelOutline" of scroll view "Scroll" of targetWindow
end initilize

on openWindow()
	set isFirst to false
	if WindowController is missing value then
		initilize()
		set isFirst to true
	end if
	set isWorkingDisplayToggleTimer to call method "isWorkingDisplayToggleTimer" of WindowController
	--activate
	call method "showWindow:" of WindowController
	if (isFirst or (isWorkingDisplayToggleTimer is 0)) then
		watchmi() of LabelListObj
	end if
end openWindow

on displayAlert(theMessage)
	display alert theMessage attached to targetWindow as warning
	script endOfAlert
		on sheetEnded(theReply)
		end sheetEnded
	end script
	
	addSheetRecord of SheetManager given parentWindow:my targetWindow, ownerObject:endOfAlert
end displayAlert