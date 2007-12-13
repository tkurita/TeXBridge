global PathConverter
global CompileCenter
global MessageUtility
global PathAnalyzer
global EditorClient
global UtilityHandlers

on extractFilePath(theCommand, theParagraph)
	if theParagraph contains theCommand then
		set pos0 to offset of theCommand in theParagraph
		set theParagraph to text pos0 thru -1 of theParagraph
		set pos1 to offset of "{" in theParagraph
		set pos2 to offset of "}" in theParagraph
		set thePath to text (pos1 + 1) thru (pos2 - 1) of theParagraph
		set fullPath to absolute_path of PathConverter for thePath
	else
		set fullPath to ""
	end if
	return fullPath
end extractFilePath

on open_parentfile()
	try
		set a_texdoc to checkmifiles of CompileCenter without saving and autosave
	on error msg number 1200
		return
	end try
	if a_texdoc's has_parent() then
		tell application "Finder"
			open (a_texdoc's file_ref()'s as_alias())
		end tell
	else
		set a_msg to UtilityHandlers's localized_string("noParentFile", a_texdoc's filename())
		EditorClient's show_message(a_msg)
	end if
end open_parentfile

on doReverseSearch(targetLine)
	tell application "System Events"
		tell application process "mi"
			keystroke "b" using command down
		end tell
	end tell
	--ignoring application responses
	tell application "mi"
		select paragraph targetLine of first document
	end tell
	--end ignoring
end doReverseSearch