property EditorClient : module "miClient"

property _nParagraph : missing value -- number of paragraph of document
property _parPosition : missing value -- index of the paragraph cursor is in
property _cursorPosition : missing value --index of insertion point of cursor from beginning of document
property _cursorPositionInPar : missing value -- index of insertion point of cursor form beginning of paragraph parPosition
property _selection_rec : missing value
property _current_text : missing value
property _parNumber : missing value
property _charNumber : missing value

on initialize()
	set my _selection_rec to EditorClient's selection_info()
	set my _parPosition to paragraphIndex of my _selection_rec
	set my _cursorPosition to cursorPosition of my _selection_rec
	set my _nParagraph to totalParapraphs of my _selection_rec
	set my _cursorPositionInPar to ((cursorInParagraph of my _selection_rec) + 1)
	set my _current_text to currentParagraph of my _selection_rec
end initialize

on paragraph_for_forwarding()
	set my _parNumber to my _parPosition
	set my _charNumber to my _cursorPositionInPar
	set a_text to EditorClient's paragraph_at(my _parPosition)
	set my _current_text to text my _cursorPositionInPar thru -1 of a_text
	return my _current_text
end paragraph_for_forwarding

on paragraph_for_reversing_from(from_par, from_char)
	set my _parNumber to from_par
	set my _charNumber to 1
	set a_text to EditorClient's paragraph_at(my _parNumber)
	if (length of a_text > 2) and (from_char is not 1) then
		set my _current_text to text 1 thru (from_char - 1) of a_text
	else
		paragraph_for_reversing_from(from_par - 1, 0)
	end if
	return my _current_text
end paragraph_for_reversing_from

on paragraph_for_reversing()
	return paragraph_for_reversing_from(my _parPosition, my _cursorPositionInPar)
end paragraph_for_reversing

on paragraph_with_increment(line_step)
	set my _parNumber to (my _parNumber) + line_step
	
	if my _parNumber > my _nParagraph then
		error "out of end of document." number 1300
	else if my _parNumber < 1 then
		error "out of beginning of document." number 1301
	end if
	
	set my _charNumber to 1
	set my _current_text to EditorClient's paragraph_at(my _parNumber)
	return my _current_text
end paragraph_with_increment

on forward_in_paragraph(a_pos)
	set my _current_text to text a_pos thru -1 of my _current_text
	set my _charNumber to (my _charNumber) + a_pos
	return my _current_text
end forward_in_paragraph

on reverse_in_paragraph(a_pos)
	set my _current_text to text 1 thru a_pos of my _current_text
	return my _current_text
end reverse_in_paragraph

on position_in_paragraph()
	return my _charNumber
end position_in_paragraph

on index_of_paragraph()
	return my _parNumber
end index_of_paragraph

on current_text()
	return my _current_text
end current_text

on cursor_position()
	return my _cursorPosition
end cursor_position

on paragraph_position()
	return my _parPosition
end paragraph_position

on cursor_in_paragraph()
	return my _cursorPositionInPar
end cursor_in_paragraph

on selection_info()
	return my _selection_rec
end selection_info
