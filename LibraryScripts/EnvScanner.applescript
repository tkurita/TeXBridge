property TeXBridgeProxy : module
property EditorClient : module "miClient"
property ScannerSource : module

property name : "EnvScanner"
property version : "1.1.1"

property _beginText : missing value
property _beginTextLength : missing value
property _endText : missing value
property _endTextLength : missing value
property _backslash : missing value

--global variable
property _beginStack : {}
property _endStack : {}
property _target_text : missing value
property _scanner_source : missing value

on debug()
	set loader to boot (module loader of application (get "TeXToolsLib")) for me
	tell make_with(make (loader's load("TeXBridgeProxy")))
		log find_begin()
		--find_next_begin()
	end tell
end debug

on run
	debug()
end run

on begin_text()
	return my _beginText
end begin_text

on end_text()
	return my _endText
end end_text

on scanner_source()
	return my _scanner_source
end scanner_source

on make_with(a_texbridge)
	set a_class to me
	tell a_texbridge
		resolve_support_plist()
		script EnvScannerInstance
			property parent : a_class
			property _texbridge : it
			property _scanner_source : make ScannerSource
			property _beginText : plist_value("beginText")
			property _beginTextLength : length of my _beginText
			property _endText : plist_value("endText")
			property _endTextLength : length of my _endText
			property _backslash : plist_value("backslash")
			property _beginStack : {}
			property _endStack : {}
			property _target_text : missing value
		end script
	end tell
	return EnvScannerInstance
end make_with

-- handlers for finding both of \begin and \end
on stripCommentText(theText, line_step)
	local theText
	set percentOffset to offset of "%" in theText
	if percentOffset is 0 then
		return theText
	else if percentOffset is 1 then
		return stripCommentText(my _scanner_source's paragraph_with_increment(line_step), line_step)
	else
		set newText to text 1 thru (percentOffset - 1) of theText
		if newText ends with my _backslash then
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
	set cha_pos to my _scanner_source's position_in_paragraph()
	
	return {enviroment:envName, startPosition:startEnvIndex + cha_pos - 1, endPosition:endEnvIndex + cha_pos - 1, linePosition:my _scanner_source's index_of_paragraph(), lineContents:""}
end getEnvRecord

on update_target_text(line_step)
	try
		set_target_text(my _scanner_source's paragraph_with_increment(line_step), line_step)
	on error msg number errno
		if errno is 1300 then
			if my _beginStack is {} then
				return
			end if
			error my _endText & space & "command can not be found."
		else if errno is 1301 then
			if my _endStack is {} then
				return
			end if
			error my _beginText & space & "command can not be found."
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
	set endEnvIndex to (endPosition of envRecord) - (my _scanner_source's position_in_paragraph())
	if length of my _target_text is endEnvIndex + 2 then
		update_target_text(1)
	else
		set my _target_text to my _scanner_source's forward_in_paragraph(endEnvIndex + 1)
	end if
	return envRecord
end getEnvRecordForEnd

on set_target_text(a_text, line_step)
	set my _target_text to stripCommentText(a_text, line_step)
end set_target_text

on find_end()
	set_target_text(my _scanner_source's paragraph_for_forwarding(), 1)
	repeat 100 times
		set endoffset to offset of my _endText in my _target_text
		set beginoffset to offset of my _beginText in my _target_text
		
		if endoffset is 0 then
			if beginoffset is 0 then
				update_target_text(1)
			else
				set beginRecord to getEnvRecordForEnd(beginoffset + (my _beginTextLength))
				set beginning of my _beginStack to beginRecord
			end if
		else
			if (beginoffset is 0) then
				-- find end
				set endRecord to getEnvRecordForEnd(endoffset + (my _endTextLength))
				if my _beginStack is {} then
					return endRecord
				else
					if (enviroment of endRecord) is (enviroment of item 1 of my _beginStack) then
						set my _beginStack to rest of my _beginStack
					end if
				end if
			else
				if (beginoffset > endoffset) then
					set beginRecord to getEnvRecordForEnd(beginoffset + (my _beginTextLength))
					set beginning of my _beginStack to beginRecord
				else
					set endRecord to getEnvRecordForEnd(endoffset + (my _endTextLength))
					if my _beginStack is {} then
						return endRecord
					else
						if (enviroment of endRecord) is (enviroment of item 1 of my _beginStack) then
							set my _beginStack to rest of my _beginStack
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
		if my _scanner_source's index_of_paragraph() is 1 then
			set my _target_text to ""
		else
			update_target_text(-1)
		end if
	else
		set my _target_text to my _scanner_source's reverse_in_paragraph(endOfLine)
	end if
	return envRecord
end getEnvRecordAtLast

on find_next_begin()
	repeat 100 times
		set endoffset to offset of my _endText in my _target_text
		set beginoffset to offset of my _beginText in my _target_text
		
		if beginoffset is 0 then
			if endoffset is 0 then
				update_target_text(-1)
			else
				set endRecord to getEnvRecordAtLast(endoffset, my _endText, my _endTextLength)
				set beginning of my _endStack to endRecord
			end if
		else
			if (endoffset is 0) then
				set beginRecord to getEnvRecordAtLast(beginoffset, my _beginText, my _beginTextLength)
				if my _endStack is {} then
					return beginRecord
				else
					if (enviroment of beginRecord) is (enviroment of item 1 of my _endStack) then
						set my _endStack to rest of my _endStack
					end if
				end if
			else
				set before_text_source to my _scanner_source's make_with_copying(my _scanner_source)
				set endRecord to getEnvRecordAtLast(endoffset, my _endText, my _endTextLength)
				set after_text_source to my _scanner_source's make_with_copying(my _scanner_source)
				set my _scanner_source to before_text_source
				set beginRecord to getEnvRecordAtLast(beginoffset, my _beginText, my _beginTextLength)
				
				if (startPosition of endRecord) > (startPosition of beginRecord) then
					set beginning of my _endStack to endRecord
					set my _scanner_source to after_text_source
				else
					if my _endStack is {} then
						return beginRecord
					else
						if (enviroment of beginRecord) is (enviroment of item 1 of my _endStack) then
							set my _endStack to rest of my _endStack
						end if
					end if
				end if
			end if
		end if
	end repeat
	return missing value -- should consider no next enviroment
end find_next_begin

on find_begin()
	set_target_text(my _scanner_source's paragraph_for_reversing(), -1)
	return find_next_begin()
end find_begin
