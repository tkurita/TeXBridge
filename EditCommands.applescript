global PathConverter
global TeXCompileObj
global MessageUtility
global yenmark

on extractFilePath(theCommand, theParagraph)
	if theParagraph contains theCommand then
		set pos0 to offset of theCommand in theParagraph
		set theParagraph to text pos0 thru -1 of theParagraph
		set pos1 to offset of "{" in theParagraph
		set pos2 to offset of "}" in theParagraph
		set thePath to text (pos1 + 1) thru (pos2 - 1) of theParagraph
		set fullPath to getAbsolutePath of PathConverter for thePath
	else
		set fullPath to ""
	end if
	return fullPath
end extractFilePath

on openRelatedFile given revealOnly:revealFlag
	try
		set theTexDocObj to checkmifiles of TeXCompileObj without saving
	on error errMsg number 1200
		return
	end try
	
	set theOriginPath to POSIX path of texFileRef of theTexDocObj
	setPOSIXoriginPath(theOriginPath) of PathConverter
	
	set commandList to {yenmark & "includegraphics", yenmark & "input", yenmark & "include"}
	tell application "mi"
		tell document 1
			set firstpara to targetParagraph of theTexDocObj
			set paracount to (count paragraphs of selection object 1)
			repeat with nth from firstpara to firstpara + paracount - 1
				set theParagraph to paragraph nth
				if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
					repeat with theCommand in commandList
						set fullPath to my extractFilePath(theCommand, theParagraph)
						if fullPath is not "" then
							try
								set fileAlias to (POSIX file fullPath) as alias
							on error
								set fileAlias to (POSIX file (fullPath & ".tex")) as alias
							end try
							if revealFlag then
								tell application "Finder"
									activate
									reveal fileAlias
								end tell
							else
								tell application "Finder" to open fileAlias
							end if
						end if
					end repeat
				end if
			end repeat
		end tell
	end tell
end openRelatedFile

on openParentFile()
	try
		set theTexDocObj to checkmifiles of TeXCompileObj without saving
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