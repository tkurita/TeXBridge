global yenmark
global PathConverter

(*
---debug code
property LibraryFolder : "IGAGURI HD:Users:tkurita:Factories:Script factory:ProjectsX:TeX Tools for mi:Library Scripts:"
property PathConverter : load script file (LibraryFolder & "PathConverter")
property yenmark : ASCII character 92
global logTree -- for debug
global loglogTree -- for debug

on run
	debug()
end run
on debug()
	set startTime to current date
	script theTexDocObj
		property logFileRef : alias ("IGAGURI HD:Users:tkurita:WorkSpace:â¡ë¨äÌï◊ã≠âÔ:ó\èK:2.19 à ëäêUìÆ:PhaseOscillation.log" as Unicode text)
		property texBasePath : "IGAGURI HD:Users:tkurita:WorkSpace:â¡ë¨äÌï◊ã≠âÔ:ó\èK:2.19 à ëäêUìÆ:PhaseOscillation" as Unicode text
	end script
	activate
	set theLogFileParser to makeObj(theTexDocObj)
	parseLogFile() of theLogFileParser
	set stopTime to current date
	set deltaTime to stopTime - startTime
	hyperlist of theLogFileParser
	--theLogFileParser
	
end debug
--end debug code
*)


on makeObj(theTexDocObj)
	script LogFileParser
		property parent : theTexDocObj
		property texFileExtensions : {".tex", ".cls", ".sty", ".dtx", ".txt", ".bbl", ".ind"}
		--property logFileRef : missing value
		property isDviOutput : true
		property hyperlist : {}
		property retryCompile : false
		property isNoError : true
		property isNoMessages : false
		
		--private property
		property logtext : missing value
		property nLine : missing value
		
		on getLogText()
			set logtext to (read my logFileRef)
			set nLine to count paragraph of logtext
		end getLogText
		
		on parseLogFile()
			getLogText()
			set linePosition to skipHeader()
			set theParagraph to text 2 thru -1 of (paragraph linePosition of logtext)
			set logTree to {{logContent:theParagraph, lineNumber:linePosition}}
			set {linePosition, charPosition} to parseBody(logTree, linePosition + 1, 1)
			set loglogTree to {{logContent:my logFileRef, lineNumber:linePosition}}
			set end of loglogTree to logTree
			parseFooter(loglogTree, linePosition, charPosition)
			setHFSoriginPath(my texBasePath) of PathConverter
			findFristLebelErrors(loglogTree)
			set isNoMessages to (hyperlist is {})
		end parseLogFile
		
		on findFristLebelErrors(theLogTree)
			local theLogTree, theTargetFile
			set nItem to length of theLogTree
			
			set theTargetFile to logContent of item 1 of theLogTree
			
			repeat with ith from 2 to nItem
				set theLogItem to item ith of theLogTree
				--log theLogItem
				--set theClass to class of theItem
				set theResult to isThisError(theLogTree, nItem, ith)
				set ith to newPosition of theResult
				set theErrorRecord to errorRecord of theResult
				if theErrorRecord is not {} then
					using terms from application "mi"
						try -- some records do not have "file" label
							set file of theErrorRecord to theTargetFile
						end try
						try
							set paragraph of theErrorRecord to lineNumber of theLogItem
						on error
							set theErrorRecord to theErrorRecord & {paragraph:lineNumber of theLogItem}
						end try
					end using terms from
					
					set end of hyperlist to theErrorRecord
				end if
			end repeat
		end findFristLebelErrors
		
		on findErrors(theLogTree)
			local theLogTree, theTargetFile
			set nItem to length of theLogTree
			
			if nItem is less than or equal to 1 then
				return
			end if
			
			set theTargetFile to item 1 of theLogTree
			set isTaragetFileResolved to false
			
			repeat with ith from 2 to nItem
				set theItem to item ith of theLogTree
				--set theClass to class of theItem
				set theResult to isThisError(theLogTree, nItem, ith)
				set ith to newPosition of theResult
				set theErrorRecord to errorRecord of theResult
				if theErrorRecord is not {} then
					if not isTaragetFileResolved then -- already resolved
						set theTargetFile to resolveTargetFile(theTargetFile, item 2 of theLogTree)
						set isTaragetFileResolved to true
					end if
					try -- some records do not have "file" label
						set file of theErrorRecord to theTargetFile
					end try
					set end of hyperlist to theErrorRecord
				end if
			end repeat
		end findErrors
		
		on resolveTargetFile(theLogItem, theNextItem)
			set theTargetFile to logContent of theLogItem
			if class of theTargetFile is alias then
				return theTargetFile
			end if
			set theTargetFile to checkTexFileExtensions(theTargetFile, logContent of theNextItem)
			
			if (theTargetFile starts with "./") or (theTargetFile starts with "../") then
				set theTargetFile to getHFSfromPOSIXpath of PathConverter for theTargetFile
				set theTargetFile to getAbsolutePath of PathConverter for theTargetFile
				set theTargetFile to theTargetFile as alias
			else
				set theTargetFile to (POSIX file theTargetFile) as alias
			end if
			return theTargetFile
		end resolveTargetFile
		
		on checkTexFileExtensions(theTargetFile, theNextLine)
			repeat with theExtension in texFileExtensions
				if theTargetFile ends with theExtension then
					return theTargetFile
				end if
			end repeat
			
			repeat with theExtension in texFileExtensions
				set endOfPath to offset of (theExtension & space) in theTargetFile
				if endOfPath is not 0 then
					set theTargetFile to text 1 thru (endOfPath + (length of theExtension) - 1) of theTargetFile
					return theTargetFile
				end if
			end repeat
			
			if theNextLine is not missing value then
				return checkTexFileExtensions(theTargetFile & theNextLine, missing value)
			else
				return theTargetFile
			end if
		end checkTexFileExtensions
		
		on isThisError(theLogTree, nItem, currentPos)
			local theLogItem, theClass, errMsg, hyperrec, theLogTree
			
			set errMsg to ""
			set hyperrec to {}
			
			set theLogItem to item currentPos of theLogTree
			set theClass to class of theLogItem
			
			if theClass is list then
				findErrors(theLogItem)
				return {newPosition:currentPos, errorRecord:hyperrec}
			else if theClass is record then
				set theLogContent to logContent of theLogItem
			end if
			
			try
				if length of theLogContent is less than 1 then
					return {newPosition:currentPos, errorRecord:hyperrec}
				end if
			on error
				return {newPosition:currentPos, errorRecord:hyperrec}
			end try
			
			if (theLogContent starts with "!") then
				set isNoError to false
				set errMsg to theLogContent
				----get Additional Infomation
				set thePos to currentPos
				repeat while (thePos < nItem)
					set thePos to thePos + 1
					set theLogItem to item thePos of theLogTree
					set theLogContent to logContent of theLogItem
					if theLogContent starts with "l." then
						set tmpstr to text 3 thru -1 of theLogContent
						set errpn to (first word of tmpstr) as integer
						
						using terms from application "mi"
							set hyperrec to {file:"", paragraph:errpn, comment:errMsg}
						end using terms from
						
						set currentPos to thePos
						exit repeat
					else if (theLogContent starts with "?") or (theLogContent starts with "Enter file name:") then
						if hyperrec is {} then
							using terms from application "mi"
								set hyperrec to {file:"", comment:errMsg}
							end using terms from
						end if
						set currentPos to thePos
						exit repeat
					end if
				end repeat
				
				if hyperrec is {} then
					using terms from application "mi"
						set hyperrec to {file:"", comment:errMsg}
					end using terms from
					set currentPos to currentPos + 1
				end if
				
			else if theLogContent contains "Warning:" then
				if theLogContent does not end with "." then
					set currentPos to currentPos + 1
					if class of item currentPos of theLogTree is record then
						set theLogContent to theLogContent & (logContent of item currentPos of theLogTree)
					end if
				end if
				
				if theLogContent contains "Label(s) may have changed. Rerun to get cross-references right." then
					set retryCompile to true
				end if
				
				if word -2 of theLogContent is "line" then
					set errpn to (last word of theLogContent) as integer
					using terms from application "mi"
						set hyperrec to {file:"", paragraph:errpn, comment:theLogContent}
					end using terms from
				else
					using terms from application "mi"
						set hyperrec to {file:"", comment:theLogContent}
					end using terms from
				end if
				
			else if (theLogContent starts with "Overfull") or (theLogContent starts with "Underfull") then
				try
					set errpn to (last word of theLogContent) as integer
					try
						set errpn to (word -2 of theLogContent) as integer
					end try
					using terms from application "mi"
						set hyperrec to {file:"", paragraph:errpn, comment:theLogContent}
					end using terms from
					set currentPos to currentPos + 1
				on error errMsg number errNum
					--display dialog errmsg
					using terms from application "mi"
						set hyperrec to {file:"", comment:theLogContent}
					end using terms from
				end try
			else if (theLogContent starts with "No file") then
				set isNoError to false
				using terms from application "mi"
					set hyperrec to {file:"", comment:theLogContent}
				end using terms from
				set currentPos to currentPos + 1
			else if theLogContent is "No pages of output." then
				set isDviOutput to false
				set isNoError to false
				using terms from application "mi"
					set hyperrec to {comment:theLogContent}
				end using terms from
			end if
			return {newPosition:currentPos, errorRecord:hyperrec}
		end isThisError
		
		on skipHeader()
			repeat with ith from 1 to nLine
				set theParagraph to paragraph ith of logtext
				if theParagraph starts with "(" then
					exit repeat
				end if
			end repeat
			return ith
		end skipHeader
		
		on parseBody(currentList, startLinePosition, startCharPosition)
			local theChar, newList, charPos, linePos
			set errorList to {}
			set linePos to startLinePosition
			set charPos to startCharPosition
			
			repeat while linePos is less than or equal to nLine
				local theParagraph
				set theParagraph to paragraph linePos of logtext
				--log theParagraph
				
				set lineLength to length of theParagraph
				if lineLength > 0 then
					if charPos is 1 then
						set newLinePos to isSpecialLine(currentList, theParagraph, linePos)
					else
						set newLinePos to linePos
					end if
					
					-- scan by character
					if newLinePos is not linePos then
						set linePos to newLinePos
					else
						repeat while charPos is less than or equal to lineLength
							set theChar to character charPos of theParagraph
							if theChar is "`" then
								set charPos to charPos + 1
								repeat while charPos is less than or equal to lineLength
									set theChar to character charPos of theParagraph
									if theChar is "'" then
										exit repeat
									end if
									set charPos to charPos + 1
								end repeat
								
								if charPos > lineLength then
									set charPos to 1
									set linePos to linePos + 1
									exit repeat
								end if
							else if theChar is ")" then
								if charPos > startCharPosition then
									set end of currentList to {logContent:text startCharPosition thru (charPos - 1) of theParagraph, lineNumber:linePos}
								end if
								if charPos is lineLength then
									return {linePos + 1, 1}
								else
									return {linePos, charPos + 1}
								end if
							else if theChar is "(" then
								--log theParagraph
								if charPos > startCharPosition then
									set end of currentList to {logContent:text startCharPosition thru (charPos - 1) of theParagraph, lineNumber:linePos}
								end if
								set newList to {}
								set end of currentList to newList
								
								if charPos is lineLength then
									set {linePos, startCharPosition} to parseBody(newList, linePos + 1, 1)
								else
									set {linePos, startCharPosition} to parseBody(newList, linePos, charPos + 1)
								end if
								
								set charPos to startCharPosition
								exit repeat
							else if charPos is lineLength then
								if charPos is greater than or equal to startCharPosition then
									set end of currentList to {logContent:text startCharPosition thru -1 of theParagraph, lineNumber:linePos}
								end if
								set linePos to linePos + 1
								set charPos to 1
								set startCharPosition to 1
								exit repeat
							end if
							set charPos to charPos + 1
						end repeat
					end if
				else
					set linePos to linePos + 1
				end if
			end repeat
			
			return {linePos, charPos}
		end parseBody
		
		on isSpecialLine(currentList, theParagraph, linePos)
			local theParagraph
			
			--log theParagraph
			if theParagraph starts with "LaTeX Font Info:" then
				--skip this line
				return linePos + 1
			else if theParagraph starts with "LaTeX Font" then
				--add to currentList
			else if theParagraph starts with "LaTeX Info" then
				--skip this line
				return linePos + 1
				--else if theParagraph starts with "LaTeX Warning:" then
				--add to currentList
			else if theParagraph contains "Warning:" then
				set theLine to theParagraph
				repeat while (theLine does not end with ".")
					set linePos to linePos + 1
					set theLine to theLine & (paragraph linePos of logtext)
				end repeat
				set end of currentList to {logContent:theLine, lineNumber:linePos}
				return linePos + 1
			else if theParagraph starts with "(Font)" then
				--add to currentList
			else if theParagraph starts with "File:" then
				if (length of theParagraph is greater than or equal to 79) then
					-- parse with char by char
					return linePos
				else
					--skip this line
					return linePos + 1
				end if
			else if (theParagraph starts with "Overfull") or (theParagraph starts with "Underfull") then
				repeat while (linePos is less than or equal to nLine)
					set theLine to paragraph linePos of logtext
					if theLine ends with "[]" then
						exit repeat
					end if
					set linePos to linePos + 1
				end repeat
				-- add to current list
				
			else if theParagraph starts with yenmark then
				--skip this line
				return linePos + 1
			else if theParagraph starts with "Runaway argument?" then
				set linePos to linePos + 1
				repeat while (linePos is less than or equal to nLine)
					set theLine to paragraph linePos of logtext
					if theLine starts with "!" then
						exit repeat
					end if
					set linePos to linePos + 1
				end repeat
				return linePos
			else if theParagraph starts with "Package hyperref" then
				-- add to current list
			else if theParagraph starts with "(hyperref)" then
				-- add to current list
			else if (theParagraph starts with "<argument>") or (theParagraph starts with "<inserted text>") then
				set linePos to linePos + 1
				repeat
					set theLine to paragraph linePos of logtext
					if theLine starts with space then
						set linePos to linePos + 1
					else
						exit repeat
					end if
				end repeat
				return linePos
			else if theParagraph starts with "l." then
				set end of currentList to {logContent:theParagraph, lineNumber:linePos}
				set linePos to linePos + 1
				repeat
					set theLine to paragraph linePos of logtext
					if theLine starts with space then
						set linePos to linePos + 1
					else
						exit repeat
					end if
				end repeat
				return linePos
			else if theParagraph starts with "!" then
				-- add to current list
				if (length of theParagraph is greater than or equal to 79) then
					--add 2 line to current list
					set theLine to theParagraph & (paragraph (linePos + 1) of logtext)
					set end of currentList to {logContent:theLine, lineNumber:linePos}
					return linePos + 2
				end if
			else
				-- parse with char by char
				return linePos
			end if
			
			set end of currentList to {logContent:theParagraph, lineNumber:linePos}
			return linePos + 1
		end isSpecialLine
		
		on parseFooter(theLogTree, linePosition, charPosition)
			if nLine < linePosition then
				return
			end if
			if charPosition is not 1 then
				set end of theLogTree to text charPosition thru -1 of paragraph linePosition of logtext
				set linePosition to linePosition + 1
			end if
			repeat with ith from linePosition to nLine
				set end of theLogTree to {logContent:(paragraph ith of logtext), lineNumber:ith}
			end repeat
		end parseFooter
	end script
	
	return LogFileParser
end makeObj
