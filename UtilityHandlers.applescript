on loadPlistDictionary(baseName)
	tell main bundle
		set plistFile to path for resource baseName extension "plist"
	end tell
	return call method "dictionaryWithContentsOfFile:" of class "NSDictionary" with parameter plistFile
end loadPlistDictionary

on getKeyValue for entryName from dictionaryValue
	return call method "valueForKey:" of dictionaryValue with parameter entryName
end getKeyValue

on stripHeadTailSpaces(theText)
	if theText starts with space then
		set theText to stripHeadTailSpaces(text 2 thru -1 of theText)
	else if theText ends with space then
		set theText to stripHeadTailSpaces(text 1 thru -2 of theText)
	else
		return theText
	end if
end stripHeadTailSpaces

on isExists(filePath)
	try
		filePath as alias
		return true
	on error
		return false
	end try
end isExists

on isRunning(appName)
	tell application "System Events"
		return exists application process appName
	end tell
end isRunning

on copyItem(sourceItem, saveLocation, newName)
	set tmpFolder to path to temporary items
	tell application "Finder"
		set theItem to (duplicate sourceItem to tmpFolder with replacing) as alias
		set name of theItem to newName
		return (move theItem to saveLocation with replacing) as alias
	end tell
end copyItem