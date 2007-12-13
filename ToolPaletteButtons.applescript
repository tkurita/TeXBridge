on clicked theObject
	set a_name to name of theObject
	if a_name is "setting" then
		script CommandHandler
			on do(an_object)
				an_object's SettingWindowController's open_window()
			end do
		end script
		open {commandClass:"action", commandScript:CommandHandler}
	else
		set CommandHandler to run script "on do(an_object)
return an_object's " & a_name & "()
end do
return me"
		open {commandClass:"compile", commandScript:CommandHandler}
	end if
	
end clicked
