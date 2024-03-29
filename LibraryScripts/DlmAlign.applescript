property XText : "@module"
property XList : "@module"
property TableRow : "@module"
property name : "DlmAlign"

on as_text()
	-- log "start as_text in DlmAlign"	
	--set dlm to space & my _dlm & space
	set indent_text to my _indent
	script to_text
		on do(tblrow)
			-- log "do in to_text in as_text in DlmAlign"
			set t to tblrow's as_text()
			return indent_text & t
		end do
	end script
	
	return my _table's map(to_text)'s as_text_with(return)
end as_text

on set_indent(a_text)
	set my _indent to a_text
	return me
end set_indent

on make_with_text(a_text, dlm, linedlm)
	set {first_indent, a_text} to XText's strip_beginning(a_text)
	
	set max_width_list to make XList
	set max_ncols to 0
	set nlinedlm to length of linedlm
	script to_tablerow
		on do(a_line)
			if a_line ends with linedlm then
				set a_line to text 1 thru (-1 * (nlinedlm + 1)) of a_line
			end if
			set tblrow to TableRow's make_with_text(a_line, dlm, linedlm)
			set ncols to tblrow's count_items()
			if ncols > max_ncols then
				set max_ncols to ncols
			end if
			return tblrow's set_max_width(max_width_list)
		end do
	end script
	
	set tbl to XList's make_with_list(paragraphs of a_text)'s map(to_tablerow)
	return make_with_table(tbl, max_ncols)'s set_indent(first_indent)
end make_with_text

on make_with_table(tbl, max_columns_number)
	set nrows to tbl's count_items()
	set max_width_list to tbl's item_at(1)'s max_width_list()
	
	repeat with n from 1 to max_columns_number
		set max_width to 0
		repeat with m from 1 to nrows
			if n > tbl's item_at(m)'s count_items() then
				exit repeat
			end if
			set w to tbl's item_at(m)'s item_at(n)'s width()
			if w > max_width then
				set max_width to w
			end if
		end repeat
		max_width_list's push(max_width)
	end repeat
	
	set a_class to me
	script DlmAlignInstance
		property parent : a_class
		--property _dlm : dlm
		property _table : tbl
		property _indent : ""
		property _max_with : max_width_list
	end script
end make_with_table

on push(a_text)
	my _table's push(XText's make_with(a_text))
	return me
end push

on unshift(a_text)
	my _table's unshift(XText's make_with(a_text))
	return me
end unshift