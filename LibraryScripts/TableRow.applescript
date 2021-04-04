property name : "TableRow"
property XText : "@module"
property XList : "@module"

script FilledText
	property parent : AppleScript
	property _tabwidth : 4
	
	on count_width(a_text)
		--log "start count_width in FilledText"
		set total_witdh to 0
		script blk_counter
			on do(num)
				--log num
				if num < 128 then
					if num is 9 then
						set w to my _tabwidth
					else
						set w to 1
					end if
				else
					set w to 2
				end if
				set total_witdh to total_witdh + w
			end do
		end script
		XList's make_with((id of a_text) as list)'s each_rush(blk_counter)
		--log "end of count_width"
		return total_witdh
	end count_width
	
	on nspaces(n)
		set x_list to make XList
		repeat n times
			x_list's push(space)
		end repeat
		return x_list's as_text_with("")
	end nspaces
	
	on fill(width)
		return my _text & nspaces(width - (my _width))
	end fill
	
	on width()
		return my _width
	end width
	
	on dump()
		return my _text
	end dump
	
	on make_with(a_text)
		set a_class to me
		set w to count_width(a_text)
		script FilledTextInstance
			property parent : a_class
			property _text : a_text
			property _width : w
		end script
	end make_with
end script

on make_with_xlist(x_list, dlm)
	script to_filledtext
		on do(w)
			--log "start do in to_filledtext : "&w
			set f_text to FilledText's make_with(XText's strip(w))
			--log "after make FilledText"
			return f_text
		end do
	end script
	--log "start make_with_xlist in TableRow"
	set x_list to x_list's map(to_filledtext)
	set a_class to me
	script TableRowInstance
		property parent : a_class
		property _xlist : x_list
		property _dlm : dlm
		property _max_width : missing value
	end script
end make_with_xlist

on make_with_text(a_text, dlm)
	return make_with_xlist(XList's make_with_text(a_text, dlm), space & dlm & space)
end make_with_text

on count_items()
	return my _xlist's count_items()
end count_items

on item_at(n)
	return my _xlist's item_at(n)
end item_at

on set_max_width(max_width_list)
	set my _max_width to max_width_list
	return me
end set_max_width

on max_width_list()
	return my _max_width
end max_width_list

on push_coloumn_width(width)
	my _max_width's push(width)
	return me
end push_coloumn_width

on as_text()
	if my _xlist's count_items() ≤ 1 then
		return _xlixt's item_at(1)
	end if
	
	set max_width_list to my _max_width's reset()
	script fill_text
		on do(fText)
			return fText's fill(max_width_list's next())
		end do
	end script
	
	return my _xlist's map(fill_text)'s as_text_with(my _dlm)
end as_text