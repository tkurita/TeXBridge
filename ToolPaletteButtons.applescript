on clicked theObject
	set theName to name of theObject
	if theName is "setting" then
		open theName
	else
		open {commandClass:"compile", commandID:theName}
	end if
end clicked
