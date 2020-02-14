property ToolServerProxy : "@module TeXBridgeProxy"
property EditorClient : "@module miClient"

property _commonHeadings : {"section", "subsection", "subsubsection", "paragraph", "subparagraph"}
property _reportHeadings : {"chapter"} -- heading for report and book class
property _backslash : missing value
property _headingList : missing value
property _docClass : missing value
property _nHead : 0

on debug()
	initialize()
	set headRecord to search_preheading()
	set preHeadLevel to previousLevel of headRecord
	if preHeadLevel is my _nHead then
		display alert previousHeading of headRecord & " ÇÃéüÇÃÉåÉxÉãÇÕÇ†ÇËÇ‹ÇπÇÒÅB"
		return
	else if preHeadLevel is missing value then
		set preHeadLevel to 1
	end if
	set a_text to selection_contents() of EditorClient
	set pretext to (item (preHeadLevel + 1) of my _headingList) & "{"
	EditorClient's insert_text(pretext & a_text & "}")
	set selinfo to EditorClient's selection_info()
	EditorClient's select_in_range((selinfo's cursorPosition) + (length of pretext), (length of a_text))
end debug

on run
	debug()
end run

on initialize()
	tell (make ToolServerProxy)
		resolve_support_plist()
		set my _backslash to plist_value("backslash")
	end tell
	build_heading_list()
end initialize

on make
	set a_class to me
	script SectionCoreInstance
		property parent : a_class
		property _backslash : missing value
		property _headingList : missing value
		property _docClass : missing value
		property _nHead : 0
	end script
	
	tell SectionCoreInstance
		initialize()
		return it
	end tell
end make

on sectioning_command(a_level)
	item a_level of my _headingList
end sectioning_command

on pickout_parameter(targetText)
	set startBracket to offset of "{" in targetText
	set endBracket to offset of "}" in targetText
	return text (startBracket + 1) thru (endBracket - 1) of targetText
end pickout_parameter

on find_doc_class()
	set docClassCommand to my _backslash & "documentclass"
	set beginDocCommand to my _backslash & "begin{document}"
	set docClass to missing value
	tell application "mi"
		tell front document
			set nPar to count paragraph
			repeat with ith from 1 to nPar
				set theLine to paragraph ith
				if theLine contains docClassCommand then
					set docClass to my pickout_parameter(theLine)
				else if theLine contains beginDocCommand then
					exit repeat
				end if
			end repeat
		end tell
	end tell
	
	return docClass
end find_doc_class

on build_heading_list()
	set docClass to find_doc_class()
	if (docClass is missing value) or (docClass contains "article") then
		set sectionList to _commonHeadings
	else
		set sectionList to _reportHeadings & _commonHeadings
	end if
	set my _headingList to {my _backslash & "part"}
	repeat with theItem in sectionList
		set end of my _headingList to my _backslash & theItem
	end repeat
	set my _nHead to length of my _headingList
end build_heading_list

on search_preheading()
	set preHeadLevel to missing value
	set preHead to missing value
	tell application "mi"
		tell document 1
			set parPosition to index of paragraph 1 of selection object 1
			repeat with i from parPosition to 1 by -1
				set currentPar to paragraph i
				repeat with j from 1 to my _nHead
					set preHead to item j of my _headingList
					if currentPar contains preHead then
						set preHeadLevel to j
						exit repeat
					end if
				end repeat
				if preHeadLevel is not missing value then
					exit repeat
				end if
			end repeat
		end tell
	end tell
	return {previousHeading:preHead, previousLevel:preHeadLevel}
end search_preheading
