(* Shared Constants *)
global _backslash

(* Shared Libraries *)
global UtilityHandlers

on findReplaceText(a_key)
	--log "start findReplaceText for " & a_key
	set new_text to call method "findTextForKey:" of class "ReplaceInputData" with parameter a_key
	try
		get new_text
		return new_text
	end try
	
	-- replace text is not found associated for key value
	error "replace text is not found." number 1270
end findReplaceText

on do()
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

