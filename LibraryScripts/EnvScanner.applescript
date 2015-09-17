property TeXBridgeProxy : module
property EditorClient : module "miClient"
property ScannerSource : module
--global ScannerSource

property name : "EnvScanner"
property version : "1.1"

property beginText : missing value
property beginTextLength : missing value
property endText : missing value
property endTextLength : missing value
property backslash : missing value

--global variable
property beginStack : {}
property endStack : {}
property _target_text : missing value

on debug()
	
end debug

on run
	--getEnvName(("\\begin{gather} "), 6)
	--find_endPosition((" \\end{gather}"))
	try
		main()
		--debug()
	on error msg number errno
		if errno is not -128 then
			display alert msg
		end if
	end try
end run

on begin_text()
	return my beginText
end begin_text

on end_text()
	return my endText
end end_text

on initialize()
	set beginStack to {}
	set endStack to {}
	tell TeXBridgeProxy's shared_instance()
		resolve_support_plist()
		set beginText to plist_value("beginText")
		set beginTextLength to length of beginText
		set endText to plist_value("endText")
		set endTextLength to length of endText
		set backslash to plist_value("backslash")
	end tell
	ScannerSource's initialize()
end initialize

-- handlers for finding both of \begin and \end
on stripCommentText(theText, line_step)
	local theText
	set percentOffset to offset of "%" in theText
	if percentOffset is 0 then
		return theText
	else if percentOffset is 1 then
		return stripCommentText(ScannerSource's paragraph_with_increment(line_step), line_step)
	else
		set newText to text 1 thru (percentOffset - 1) of theText
		if newText ends with backslash then
			set restText to stripCommentText(text (percentOffset + 1) thru -1 of theText, line_step)
			return newText & "%" & restText
		else
			return newText
		end if
	end if
end stripCommentText

on getEnvRecord(targetPos)
	local startEnvIndex
	local endEnvIndex
	local theText
	local envName
	set a_text to text targetPos thru -1 of my _target_text
	--log theLine
	set startEnvIndex to offset of "{" in a_text
	if startEnvIndex is 0 then
		error "'{' can not be found in '" & my _target_text & "'"
	end if
	set startEnvIndex to targetPos + startEnvIndex
	set endEnvIndex to offset of "}" in a_text
	if endEnvIndex is 0 then
		error "'}' can not be found in '" & my _target_text & "'"
	end if
	set endEnvIndex to targetPos + endEnvIndex - 2
	set envName to text startEnvIndex thru endEnvIndex of my _target_text
	--log envName
	set cha_pos to ScannerSource's position_in_paragraph()
	
	return {enviroment:envName, startPosition:startEnvIndex + cha_pos - 1, endPosition:endEnvIndex + cha_pos - 1, linePosition:ScannerSource's index_of_paragraph(), lineContents:""}
end getEnvRecord

on update_target_text(line_step)
	try
		set_target_text(ScannerSource's paragraph_with_increment(line_step), line_step)
	on error msg number errno
		if errno is 1300 then
			if beginStack is {} then
				return
			end if
			error endText & space & "command can not be found."
		else if errno is 1301 then
			if endStack is {} then
				return
			end if
			error beginText & space & "command can not be found."
		else
			error msg number errno
		end if
	end try
end update_target_text

(***** find end position *****)
on getEnvRecordForEnd(targetPos)
	local envRecord
	local endEnvIndex
	set envRecord to getEnvRecord(targetPos)
	set endEnvIndex to (endPosition of envRecord) - (ScannerSource's position_in_paragraph())
	if length of my _target_text is endEnvIndex + 2 then
		update_target_text(1)
	else
		set my _target_text to ScannerSource's forward_in_paragraph(endEnvIndex + 1)
	end if
	return envRecord
end getEnvRecordForEnd

on set_target_text(a_text, line_step)
	set my _target_text to stripCommentText(a_text, line_step)
end set_target_text

on find_end()
	set_target_text(ScannerSource's paragraph_for_forwarding(), 1)
	repeat 100 times
		set endoffset to offset of endText in my _target_text
		set beginoffset to offset of beginText in my _target_text
		
		if endoffset is 0 then
			if beginoffset is 0 then
				update_target_text(1)
			else
				set beginRecord to getEnvRecordForEnd(beginoffset + beginTextLength)
				set beginning of beginStack to beginRecord
			end if
		else
			if (beginoffset is 0) then
				-- find end
				set endRecord to getEnvRecordForEnd(endoffset + endTextLength)
				if beginStack is {} then
					return endRecord
				else
					if (enviroment of endRecord) is (enviroment of item 1 of beginStack) then
						set beginStack to rest of beginStack
					end if
				end if
			else
				if (beginoffset > endoffset) then
					set beginRecord to getEnvRecordForEnd(beginoffset + beginTextLength)
					set beginning of beginStack to beginRecord
				else
					set endRecord to getEnvRecordForEnd(endoffset + endTextLength)
					if beginStack is {} then
						return endRecord
					else
						if (enviroment of endRecord) is (enviroment of item 1 of beginStack) then
							set beginStack to rest of beginStack
						end if
					end if
				end if
			end if
		end if
	end repeat
	return missing value
end find_end

(***** find begin command *****)

on getLastOffset(firstOffset, comText, comLength, theText)
	set theText to text (firstOffset + comLength) thru -1 of theText
	set nextOffset to offset of comText in theText
	
	if nextOffset is not 0 then
		set lastOffset to getLastOffset(nextOffset, comText, comLength, theText)
		set lastOffset to firstOffset + comLength + lastOffset - 1
		return lastOffset
	else
		return firstOffset
	end if
end getLastOffset

on getEnvRecordAtLast(firstOffset, comText, comLength)
	set lastOffset to getLastOffset(firstOffset, comText, comLength, my _target_text)
	set envRecord to getEnvRecord(lastOffset + comLength)
	set endOfLine to lastOffset - 1
	if endOfLine is 0 then
		if ScannerSource's index_of_paragraph() is 1 then
			set my _target_text to ""
		else
			update_target_text(-1)
		end if
	else
		set my _target_text to ScannerSource's reverse_in_paragraph(endOfLine)
	end if
	return envRecord
end getEnvRecordAtLast

on find_next_begin()
	repeat 100 times
		set endoffset to offset of endText in my _target_text
		set beginoffset to offset of beginText in my _target_text
		
		if beginoffset is 0 then
			if endoffset is 0 then
				update_target_text(-1)
			else
				set endRecord to getEnvRecordAtLast(endoffset, endText, endTextLength)
				set beginning of endStack to endRecord
			end if
		else
			if (endoffset is 0) then
				set beginRecord to getEnvRecordAtLast(beginoffset, beginText, beginTextLength)
				if endStack is {} then
					return beginRecord
				else
					if (enviroment of beginRecord) is (enviroment of item 1 of endStack) then
						set endStack to rest of endStack
					end if
				end if
			else
				
				copy ScannerSource to before_text_source
				set endRecord to getEnvRecordAtLast(endoffset, endText, endTextLength)
				copy ScannerSource to after_text_source
				set ScannerSource to before_text_source
				set beginRecord to getEnvRecordAtLast(beginoffset, beginText, beginTextLength)
				
				if (startPosition of endRecord) > (startPosition of beginRecord) then
					set beginning of endStack to endRecord
					set ScannerSource to after_text_source
				else
					if endStack is {} then
						return beginRecord
					else
						if (enviroment of beginRecord) is (enviroment of item 1 of endStack) then
							set endStack to rest of endStack
						end if
					end if
				end if
			end if
		end if
	end repeat
	return missing value
end find_next_begin

on find_begin()
	set_target_text(ScannerSource's paragraph_for_reversing(), -1)
	return find_next_begin()
end find_begin
