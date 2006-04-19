global yenmark
global _backslash
global RefPanelController
global KeyValueDictionary
global StringEngine
global PathConverter
global PathAnalyzer

(*
property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property KeyValueDictionary : load script file (LibraryFolder & "KeyValueDictionary.scpt")
property StringEngine : load script file (LibraryFolder & "StringEngine.scpt")
property PathAnalyzer : load script file (LibraryFolder & "PathAnalyzer.scpt")
property PathConverter : load script file (LibraryFolder & "PathConverter.scpt")
*)

property auxObjArray : missing value
property labelDataSource : missing value
property unsavedAuxObj : missing value
property outlineView : missing value

property ignoringErrors : {1230, 1500}

on initialize(theDataSource)
	set auxObjArray to makeObj() of KeyValueDictionary
	set labelDataSource to theDataSource
	tell labelDataSource
		make new data column at the end of the data columns with properties {name:"label"}
		make new data column at the end of the data columns with properties {name:"reference"}
	end tell
end initialize

on watchmi()
	--log "start watchmi"
	try
		set resultRecord to findAuxObjFromDoc()
	on error errMsg number errNum
		if errNum is in {1230, 1500} then
			-- 1230 : ParentFile is invalid.
			-- 1500 : Unsupported File.
			return
		else
			error errMsg number errNum
		end if
	end try
	set theAuxObj to targetAuxObj of resultRecord
	
	if theAuxObj is not missing value then
		if dataItemRef of theAuxObj is missing value then
			--log "exists item"
			if auxFileRef of theAuxObj is not missing value then
				parseAuxFile(theAuxObj)
			end if
			if hasParentFile of resultRecord then
				--log "has ParentFile"
				set auxObjofDoc to findAuxObj(currentTexFile of resultRecord, isSaved of resultRecord)
				findLabelsFromDocument(auxObjofDoc)
				--appendToOutline for auxObjofDoc below labelDataSource
			else
				--log "no ParentFile"
				findLabelsFromDocument(theAuxObj)
			end if
			appendToOutline for theAuxObj below labelDataSource
		else
			if hasParentFile of resultRecord then
				set theAuxObj to findAuxObj(currentTexFile of resultRecord, isSaved of resultRecord)
			end if
			--log "before findLabelsFromDocument"
			findLabelsFromDocument(theAuxObj)
			--log "before updateLabelsFromDoc"
			updateLabelsFromDoc() of theAuxObj
			
		end if
	end if
	--log "end of watchmi"
end watchmi

on findAuxObjFromDoc()
	--log "start findAuxObjFromDoc"
	set resultRecord to {hasParentFile:false, targetAuxObj:missing value, currentTexFile:missing value, isSaved:false}
	try
		tell application "mi"
			tell document 1
				set texFile to file
				if mode is not "TEX" then
					--log "front window is not supported mode"
					return resultRecord
				end if
			end tell
		end tell
	on error errMsg number -1728
		--log "No opend window"
		(*
		set theMessage to localized string "noDocument"
		showMessage(theMessage) of MessageUtility
		error "No opened documents." number 1240
		*)
		return resultRecord
	end try
	--log "after getting mi file in findAuxObjFromDoc"
	
	try
		set texFile to texFile as alias
		set currentTexFile of resultRecord to texFile
		set saveFlag to true
		set isSaved of resultRecord to saveFlag
	on error
		tell application "mi"
			set texFile to name of document 1
		end tell
		set saveFlag to false
		set targetAuxObj of resultRecord to findAuxObj(texFile, saveFlag)
		return resultRecord
	end try
	--log "after checking mi file status"
	
	--find ParentFile
	set parentFile to missing value
	tell application "mi"
		set ith to 1
		repeat
			set theParagraph to paragraph ith of document 1
			if theParagraph starts with "%" then
				if theParagraph starts with "%ParentFile" then
					set parentFile to StringEngine's stripHeadTailSpaces(text 13 thru -2 of theParagraph)
					exit repeat
				end if
				set ith to ith + 1
			else
				exit repeat
			end if
		end repeat
	end tell
	
	if parentFile is missing value then
		set targetAuxObj of resultRecord to findAuxObj(texFile, saveFlag)
		return resultRecord
	end if
	
	set hasParentFile of resultRecord to true
	--tell me to log parentFile
	if parentFile starts with ":" then
		setHFSoriginPath(texFile) of PathConverter
		set texFile to getAbsolutePath of PathConverter for parentFile
	else
		set texFile to parentFile
	end if
	
	--tell me to log "theTexFile : " & theTexFile
	if texFile ends with ":" then
		set sQ to localized string "startQuote"
		set eQ to localized string "endQuote"
		set textIsInvalid to localized string "isInvalid"
		set theMessage to "ParentFile" & space & sQ & parentFile & eQ & return & textIsInvalid
		displayAlert(theMessage) of RefPanelController
		--showMessageOnmi(theMessage) of MessageUtility
		error "ParentFile is invalid." number 1230
	end if
	
	set targetAuxObj of resultRecord to findAuxObj(texFile, saveFlag)
	--log "end  findAuxObjFromDoc"
	return resultRecord
end findAuxObjFromDoc

on appendToOutline for theAuxObj below parentDataItem
	--log "start appendToOutline"
	if dataItemRef of theAuxObj is missing value then
		--log "is first append to outline"
		set titleItem to make new data item at end of data items of parentDataItem
		set dataItemRef of theAuxObj to titleItem
		set contents of data cell "label" of titleItem to baseName of theAuxObj
	else
		--log "before updateLabels in appendToOutline"
		updateLabels() of theAuxObj
		return
	end if
	
	--log "before repeat in appendToOutline"
	repeat with theLabelRecord in {labelRecordFromAux of theAuxObj, labelRecordFromDoc of theAuxObj}
		repeat with ith from 1 to length of theLabelRecord
			set theItem to item ith of theLabelRecord
			set theClass to class of theItem
			if theClass is record then
				set theDataItem to make new data item at end of data items of titleItem
				set contents of data cell "label" of theDataItem to |label| of theItem
				set contents of data cell "reference" of theDataItem to |reference| of theItem
			else if theClass is script then
				appendToOutline for theItem below titleItem
			end if
		end repeat
	end repeat
	--log "before expandDataItem"
	expandDataItem() of theAuxObj
	--log "end appndToOutline"
end appendToOutline

on findAuxObj(theFileRef, isSaved)
	--log "start findAuxObj"
	set theFilePath to theFileRef as Unicode text
	
	if isSaved then
		--log "file is saved"
		set pathRecord to do(theFileRef) of PathAnalyzer
		set nameWithSuffix to name of pathRecord
		if nameWithSuffix ends with ".tex" then
			set theBaseName to text 1 thru -5 of nameWithSuffix
			set theTexFileRef to theFileRef
			try
				set theAuxFileRef to ((folderReference of pathRecord as Unicode text) & theBaseName & ".aux") as alias
			on error
				--log "aux file is not found."
				set theAuxFileRef to missing value
			end try
		else if nameWithSuffix ends with ".aux" then
			set theBaseName to text 1 thru -5 of nameWithSuffix
			set theAuxFileRef to theFileRef
			set theTexFileRef to missing value
		else
			--log "unknow suffix"
			--error "Unsupported File." number 1500
			set theBaseName to nameWithSuffix
			set theTexFileRef to theFileRef
			try
				set theAuxFileRef to ((folderReference of pathRecord as Unicode text) & theBaseName & ".aux") as alias
			on error
				--log "aux file is not found."
				set theAuxFileRef to missing value
			end try
		end if
		
		set auxObjKey to (folderReference of pathRecord as Unicode text) & theBaseName
		set theAuxObj to getValue of auxObjArray given forKey:auxObjKey
		if theAuxObj is missing value then
			--log "new auxObj is registered"
			set theAuxObj to newAuxObj(theTexFileRef, theAuxFileRef, theBaseName, isSaved)
			setValue of auxObjArray given forKey:auxObjKey, withValue:theAuxObj
		end if
	else
		--log "file is not saved"
		if unsavedAuxObj is not missing value then
			deleteDataItem() of unsavedAuxObj
		end if
		set unsavedAuxObj to newAuxObj(missing value, missing value, theFileRef, isSaved)
		set theAuxObj to unsavedAuxObj
	end if
	
	--log "end findAuxObj"
	return theAuxObj
end findAuxObj

on newAuxObj(theTexFileRef, theAuxFileRef, theBaseName, isSaved)
	--log "start newAuxObj"
	script AuxObj
		property texFileRef : theTexFileRef
		property auxFileRef : theAuxFileRef
		property labelRecordFromAux : {}
		property labelRecordFromDoc : {}
		property labelList : {}
		property baseName : theBaseName
		--property folderAlias : theFolderAlias
		property isExpanded : missing value
		property dataItemRef : missing value
		
		on checkAuxFile()
			if auxFileRef is missing value then
				set texFilePath to texFileRef as Unicode text
				if texFilePath ends with ".tex" then
					set pathWithoutSuffx to text 1 thru -5 of texFilePath
				end if
				try
					set auxFileRef to pathWithoutSuffx & ".aux" as alias
					return true
				on error
					set theMessage to localized string "auxFileIsNotFound"
					displayAlert(theMessage) of RefPanelController
					return false
				end try
			else
				return true
			end if
		end checkAuxFile
		
		on getFileContents()
			return read auxFileRef
		end getFileContents
		
		on addLabelFromAux(theLabel, theRef)
			set end of labelRecordFromAux to {|label|:theLabel, |reference|:theRef}
			set end of labelList to theLabel
		end addLabelFromAux
		
		on addChildAuxObj(theAuxObj)
			set end of labelRecordFromAux to theAuxObj
		end addChildAuxObj
		
		on addLabelFromDoc(theLabel)
			--log "start addLabelFromDoc"
			set end of labelRecordFromDoc to {|label|:theLabel, |reference|:"--"}
			--log "end addLabelFromDoc"
		end addLabelFromDoc
		
		on expandDataItem()
			--log "start expandDataItem"
			-- when epanded outline, it seems that width of table column is changed uncorrectly.
			-- fix table column width between before exapand and after expand
			set currentLabelWidth to width of table column "label" of outlineView
			set currentRefWidth to width of table column "reference" of outlineView
			call method "expandItem:" of outlineView with parameter dataItemRef
			set width of table column "label" of outlineView to currentLabelWidth
			set width of table column "reference" of outlineView to currentRefWidth
		end expandDataItem
		
		on deleteDataItem()
			set labelRecordFromAux to {}
			set labelRecordFromDoc to {}
			delete dataItemRef
		end deleteDataItem
		
		on deleteChildDataItem()
			if dataItemRef is not missing value then
				set labelRecordFromAux to {}
				set labelRecordFromDoc to {}
				delete (every data item of dataItemRef)
			end if
		end deleteChildDataItem
		
		on updateLabels()
			--log "start updateLabels"
			set nDataItem to count data item of dataItemRef
			set nLabelFromAux to length of labelRecordFromAux
			set nLabelFromDoc to length of labelRecordFromDoc
			set dItemCounter to 1
			--log "before repeat 1"
			--log "nDataItem:" & nDataItem
			--log "nLabelFromAux:" & nLabelFromAux
			--log "nLabelFromDoc:" & nLabelFromDoc
			
			repeat with ith from 1 to nLabelFromAux
				if ith is less than or equal to nDataItem then
					set theDataItem to data item ith of dataItemRef
				else
					set theDataItem to make new data item at end of data items of dataItemRef
				end if
				
				set theItem to item ith of labelRecordFromAux
				set theClass to class of theItem
				if theClass is record then
					set contents of data cell "label" of theDataItem to |label| of theItem
					set contents of data cell "reference" of theDataItem to |reference| of theItem
					if has data items of theDataItem then
						delete every data item of theDataItem
					end if
				else if theClass is script then
					set dataItemRef of theItem to theDataItem
					set contents of data cell "label" of theDataItem to baseName of theItem
					set contents of data cell "reference" of theDataItem to ""
					updateLabels() of theItem
				end if
			end repeat
			
			--log "start second repeat"
			repeat with ith from 1 to nLabelFromDoc
				if (ith + nLabelFromAux) is less than or equal to nDataItem then
					set theDataItem to data item ith of dataItemRef
				else
					set theDataItem to make new data item at end of data items of dataItemRef
				end if
				
				set theItem to item ith of nLabelFromDoc
				set contents of data cell "label" of theDataItem to |label| of theItem
				set contents of data cell "reference" of theDataItem to |reference| of theItem
			end repeat
			
			--log "start third repeat"
			set delItemNum to (nLabelFromAux + nLabelFromDoc + 1)
			repeat (nDataItem - nLabelFromAux - nLabelFromDoc) times
				delete data item delItemNum of dataItemRef
			end repeat
			--log "end of updateLabels"
		end updateLabels
		
		on updateLabelsFromDoc()
			set nDataItem to count data item of dataItemRef
			set nLabelFromAux to length of labelRecordFromAux
			set nLabelFromDoc to length of labelRecordFromDoc
			
			set labCounter to 1
			(*
			--log "before repeat 1"
			--log "nDataItem:" & nDataItem
			--log "nLabelFromAux:" & nLabelFromAux
			--log "nLabelFromDoc:" & nLabelFromDoc
			*)
			repeat with ith from (nLabelFromAux + 1) to nDataItem
				--log "in repeat 1"
				set theDataItem to data item ith of dataItemRef
				
				if labCounter is less than or equal to nLabelFromDoc then
					set theItem to item labCounter of labelRecordFromDoc
					set contents of data cell "label" of theDataItem to |label| of theItem
					set contents of data cell "reference" of theDataItem to |reference| of theItem
				else
					delete theDataItem
				end if
				set labCounter to labCounter + 1
			end repeat
			
			--log "before repeat 2"
			repeat with ith from labCounter to nLabelFromDoc
				--log "in repeat 2"
				set theItem to item ith of labelRecordFromDoc
				set theDataItem to make new data item at end of data items of dataItemRef
				set contents of data cell "label" of theDataItem to |label| of theItem
				set contents of data cell "reference" of theDataItem to |reference| of theItem
			end repeat
		end updateLabelsFromDoc
		
		on clearLabelsFromDoc()
			--log "start clearLabelsFromDoc"
			set labelRecordFromDoc to {}
			repeat with theLabelRecord in labelRecordFromAux
				if class of theLabelRecord is script then
					clearLabelsFromDoc() of theLabelRecord
				end if
			end repeat
			--log "end clearLabelsFromDoc"
		end clearLabelsFromDoc
		
		on clearLabelsFromAux()
			(*
			repeat with theLabelRecord in labelRecordFromAux
				if class of theLabelRecord is script then
					clearLabelsFromAux() of theLabelRecord
					set dataItemRef of theLabelRecord to missing value
				end if
			end repeat
			*)
			set labelRecordFromAux to {}
		end clearLabelsFromAux
		
		on appendLabelsFromDoc()
			repeat with ith from 1 to length of labelRecordFromDoc
				set theItem to item ith of labelRecordFromDoc
				set theDataItem to make new data item at end of data items of dataItemRef
				set contents of data cell "label" of theDataItem to |label| of theItem
				set contents of data cell "reference" of theDataItem to |reference| of theItem
			end repeat
		end appendLabelsFromDoc
	end script
	--log "end newAuxObj"
	return AuxObj
end newAuxObj

on parseAuxFile(theAuxObj)
	--log "start parseAuxFile"
	set theContents to getFileContents() of theAuxObj
	--log "before clearLabelsFromAux in parseAuxFile"
	clearLabelsFromAux() of theAuxObj
	--log "start repeat in parseAuxFile"
	set newlabelText to yenmark & "newlabel{"
	set inputText to yenmark & "@input{"
	repeat with ith from 1 to (count paragraph of theContents)
		set theParagraph to paragraph ith of theContents
		if (theParagraph as Unicode text) starts with newlabelText then
			--log "start with newlabelText"
			set theParagraph to text 11 thru -2 of theParagraph
			storeDelimiter() of StringEngine
			set theTextItemList to everyTextItem of StringEngine from theParagraph by "}{"
			restoreDelimiter() of StringEngine
			try
				set theRef to ((item -2 of theTextItemList) as string)
			on error
				set theRef to "--"
			end try
			
			set pos2 to (offset of "}{" in theParagraph) as integer
			set theLabel to item 1 of theTextItemList
			
			if not theLabel is "" then
				addLabelFromAux(theLabel, theRef) of theAuxObj
			end if
		else if theParagraph starts with inputText then
			--log "start @input"
			set childAuxFile to text 9 thru -2 of theParagraph
			setPOSIXoriginPath(POSIX path of (auxFileRef of theAuxObj)) of PathConverter
			set theAuxFile to getAbsolutePath of PathConverter for childAuxFile
			set theAuxFile to (POSIX file theAuxFile) as alias
			set childAuxObj to findAuxObj(theAuxFile, true)
			if childAuxObj is not missing value then
				parseAuxFile(childAuxObj)
				addChildAuxObj(childAuxObj) of theAuxObj
			end if
			--log "end @input"
		end if
	end repeat
	--log "end of parseAuxFile"
end parseAuxFile

on findLabelsFromDocument(theAuxObj)
	--log "start findLabelsFromDocument"
	tell application "mi"
		set theContents to content of document 1
	end tell
	clearLabelsFromDoc() of theAuxObj
	set labelCommand to _backslash & "label"
	--log "before repeat"
	repeat with ith from 1 to (count paragraph of theContents)
		set theParagraph to paragraph ith of theContents
		--log theParagraph
		if ((length of theParagraph) > 1) and (theParagraph does not start with "%") then
			repeat while (theParagraph contains labelCommand)
				set pos0 to offset of labelCommand in theParagraph
				set theParagraph to text pos0 thru -1 of theParagraph
				set pos1 to offset of "{" in theParagraph
				if pos1 is 0 then exit repeat
				set pos2 to offset of "}" in theParagraph
				if pos2 is 0 then exit repeat
				set theLabel to text (pos1 + 1) thru (pos2 - 1) of theParagraph
				if theLabel is not in labelList of theAuxObj then
					addLabelFromDoc(theLabel) of theAuxObj
				end if
				try
					set theParagraph to text (pos2 + 1) thru -1 of theParagraph
				on error
					exit repeat
				end try
			end repeat
		end if
	end repeat
	--log "end findLabelsFromDocument"
end findLabelsFromDocument

on rebuildLabelsFromAux(theTexFileRef)
	--log "start rebuildLabelsFromAux"
	set theAuxObj to findAuxObj(theTexFileRef, true)
	if not (checkAuxFile() of theAuxObj) then
		return
	end if
	--log "before parseAuxFile in rebuildLabelsFromAux"
	parseAuxFile(theAuxObj)
	--log "before clearLabelsFromDoc in rebuildLabelsFromAux"
	clearLabelsFromDoc() of theAuxObj
	appendToOutline for theAuxObj below labelDataSource
	--log "end of rebuildLabelsFromAux"
end rebuildLabelsFromAux