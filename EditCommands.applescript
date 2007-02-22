global PathConverter
global TeXCompileObj
global MessageUtility
global PathAnalyzer
global EditorClient

global _backslash

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

on openRelatedFile given revealOnly:revealFlag
	--log "start openRelatedFile"
	try
		set theTexDocObj to checkmifiles of TeXCompileObj without saving and autosave
	on error errMsg number errNum
		if errNum is not in ignoringErrorList of TeXCompileObj then
			showError(errNum, "openRelatedFile", errMsg) of MessageUtility
		end if
		return
	end try
	
	set theOriginPath to POSIX path of texFileRef of theTexDocObj
	--setPOSIXoriginPath(theOriginPath) of PathConverter
	set_base_path(theOriginPath) of PathConverter
	
	set incGraphicCommand to (_backslash & "includegraphics" as Unicode text)
	set bibCommand to _backslash & "bibliography"
	set commandList to {_backslash & "includegraphics", _backslash & "input", _backslash & "include", bibCommand}
	
	set firstpara to targetParagraph of theTexDocObj
	set paracount to EditorClient's count_paragraph()
	repeat with nth from firstpara to firstpara + paracount - 1
		set theParagraph to EditorClient's paragraph_at_index(nth)
		if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
			repeat with theCommand in commandList
				set fullPath to my extractFilePath(theCommand, theParagraph)
				if fullPath is not "" then
					try
						set fileAlias to (POSIX file fullPath) as alias
					on error
						if (theCommand as Unicode text) is bibCommand then
							set pathWithSuffix to fullPath & ".bib"
						else
							set pathWithSuffix to fullPath & ".tex"
						end if
						try
							set fileAlias to (POSIX file pathWithSuffix) as alias
						on error
							set sQ to localized string "startQuote"
							set eQ to localized string "endQuote"
							set theMessage to sQ & pathWithSuffix & eQ & return & return & (localized string "isNotFound")
							showMessageOnmi(theMessage) of MessageUtility
							return
						end try
					end try
					
					if revealFlag then
						tell application "Finder"
							reveal fileAlias
						end tell
						call method "activateAppOfIdentifer:" of class "SmartActivate" with parameter "com.apple.finder"
					else
						if (theCommand as Unicode text) is incGraphicCommand then
							--log "is graphic file"
							openGraphicFile(fileAlias)
						else
							tell application "Finder" to open fileAlias
						end if
					end if
					exit repeat
				end if
			end repeat
		end if
	end repeat
	
end openRelatedFile

on openGraphicFile(fileAlias)
	set pathRecord to do(fileAlias) of PathAnalyzer
	set theName to name of pathRecord
	set graphicExtensions to {".pdf", ".jpg", ".jpeg", ".png", "eps"}
	set baseName to theName
	repeat with theSuffix in graphicExtensions
		if theName ends with theSuffix then
			set baseName to text 1 thru (-1 * ((length of theSuffix) + 1)) of theName
			exit repeat
		end if
	end repeat
	
	set theFolder to folderReference of pathRecord
	tell application "Finder"
		set graphicFileNames to name of files of theFolder whose name starts with baseName
	end tell
	
	set selectGraphicFileText to localized string "selectGraphicFile"
	tell application "mi"
		set selectedGraphics to choose from list graphicFileNames with prompt selectGraphicFileText
	end tell
	if class of selectedGraphics is not list then
		return
	end if
	
	tell application "Finder"
		ignoring application responses
			repeat with theGraphic in selectedGraphics
				open file theGraphic of theFolder
			end repeat
		end ignoring
	end tell
end openGraphicFile

on openParentFile()
	try
		set theTexDocObj to checkmifiles of TeXCompileObj without saving and autosave
	on error errMsg number 1200
		return
	end try
	if hasParentFile of theTexDocObj then
		tell application "Finder"
			open texFileRef of theTexDocObj
		end tell
	else
		set aDocument to localized string "aDocument"
		set noParentFile to localized string "noParentFile"
		set sQ to localized string "startQuote"
		set eQ to localized string "endQuote"
		set theMessage to aDocument & space & sQ & (texFileName of theTexDocObj) & eQ & space & noParentFile
		showMessageOnmi(theMessage) of MessageUtility
	end if
end openParentFile

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