property alertRecordList : {}
property alertRecordLength : 0

on addAlertRecordWith(theAlertRecord)
	set end of alertRecordList to theAlertRecord
	set alertRecordLength to alertRecordLength + 1
end addAlertRecordWith

on addAlertRecrod for theObject
	set theAlertRecord to {alertWindow:window 1, ownerObject:theObject}
	addAlertRecordWith(theAlertRecord)
end addAlertRecrod

on transferToOwner for theReply from theWindow
	repeat with ith from 1 to alertRecordLength
		set theAlertRecord to item ith of alertRecordList
		if alertWindow of theAlertRecord is theWindow then
			exit repeat
		end if
	end repeat
	
	if ith is 1 then
		set alertRecordList to rest of alertRecordList
	else if ith is alertRecordLength then
		set alertRecordList to items 1 thru -2 of alertRecordList
	else
		set alertRecordList to ((items 1 thru (ith - 1) of alertRecordList) & (items (ith + 1) thru -1 of alertRecordList))
	end if
	
	set alertRecordLength to alertRecordLength - 1
	
	tell ownerObject of theAlertRecord
		alertEnded of it for theAlertRecord given dialgReply:theReply
	end tell
end transferToOwner