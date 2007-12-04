global UtilityHandlers
global TerminalCommander
global PDFObj
global PathConverter

global comDelim

script XdviDriver
	on set_file_type(dviFileRef)
		-- do nothing
	end set_file_type
	
	on openDVI given sender:theDviObj, activation:aFlag
		set x11AppName to "X11"
		if not (isRunning(x11AppName) of UtilityHandlers) then
			tell application x11AppName
				launch
			end tell
		end if
		
		getSrcSpecialFlag() of theDviObj
		set cdCommand to "cd " & (quoted form of (theDviObj's pwd()'s posix_path()))
		set dviFileName to theDviObj's name_for_suffix(".dvi")
		
		set dviViewCommand to contents of default entry "dviViewCommand" of user defaults
		if theDviObj's src_special() then
			if theDviObj's has_parent() then
				--set_base_path(POSIX path of (theDviObj's file_ref())) of PathConverter
				set_base_path(theDviObj's file_ref()'s posix_path()) of PathConverter
				set sourceFile to relative_path of PathConverter for (theDviObj's target_file()'s posix_path())
			else
				set sourceFile to theDviObj's fileName()
			end if
			
			set allCommand to cdCommand & comDelim & dviViewCommand & " -sourceposition '" & (theDviObj's doc_position()) & space & sourceFile & "' '" & dviFileName & "' &"
			doCommands of TerminalCommander for allCommand without activation
		else
			try
				set pid to do shell script "ps -o pid,command|awk '/xdvi.bin.*" & dviFileName & "$/{print $1}'"
			on error errMsg number 1
				set pid to ""
			end try
			
			if pid is "" then
				set allCommand to cdCommand & comDelim & dviViewCommand & space & "'" & dviFileName & "' &"
				doCommands of TerminalCommander for allCommand without activation
			else
				set pid to word 1 of pid
				do shell script "kill -USR1" & space & pid --reread
			end if
		end if
	end openDVI
end script

script SimpleDriver
	on set_file_type(dviFileRef)
		-- do nothing
	end set_file_type
	
	on openDVI given sender:theDviObj, activation:aFlag
		open_outfile(".dvi") of theDviObj
	end openDVI
end script

script MxdviDriver
	on set_file_type(dviFileRef)
		tell application "Finder"
			set creator type of dviFileRef to "Mxdv"
			set file type of dviFileRef to "JDVI"
		end tell
	end set_file_type
	
	on openDVI given sender:theDviObj, activation:aFlag
		--log "start openDVI of MxdviDriver"
		try
			set mxdviApp to path to application "Mxdvi" as alias
		on error
			set theMessage to localized string "mxdviIsnotFound"
			error theMessage number 1260
		end try
		getSrcSpecialFlag() of theDviObj
		--log "success getSrcSpecialFlag"
		if theDviObj's src_special() then
			set mxdviPath to quoted form of POSIX path of ((mxdviApp as Unicode text) & "Contents:MacOS:Mxdvi")
			set targetDviPath to quoted form of (POSIX path of (dviFileRef of theDviObj))
			set allCommand to mxdviPath & "  -sourceposition " & (theDviObj's doc_position()) & space & targetDviPath
			log allCommand
			if theDviObj's is_use_term() then
				doCommands of TerminalCommander for allCommand without activation
			else
				do shell script allCommand
			end if
		else
			tell application (mxdviApp as Unicode text)
				open dviFileRef of theDviObj
			end tell
		end if
		--log "end openDVI"
	end openDVI
end script

on makeObj(theTexDocObj)
	--log "start makeObj of DVIObj"
	script DviObj
		property parent : theTexDocObj
		property dviFileRef : missing value
		property _isSrcSpecial : missing value
		property DVIDriver : SimpleDriver
		
		on set_src_special(a_flag)
			set my _isSrcSpecial to a_flag
		end set_src_special
		
		on src_special()
			return my _isSrcSpecial
		end src_special
		
		on set_file_type()
			set_file_type(my dviFileRef) of my DVIDriver
		end set_file_type
		
		on setDVIDriver()
			--log "start setDVIDriver"
			set DVIPreviewMode to contents of default entry "DVIPreviewMode" of user defaults
			--log "after get DVIPreviewMode"
			if DVIPreviewMode is 0 then
				set DVIDriver to SimpleDriver
			else if DVIPreviewMode is 1 then
				set DVIDriver to MxdviDriver
			else if DVIPreviewMode is 2 then
				set DVIDriver to XdviDriver
			else
				--log "DVI Preview setting is invalid."
				error "DVI Preview setting is invalid." number 1290
			end if
			--log "end setDVIDriver"
		end setDVIDriver
		
		on getModDate()
			return modification date of (info for dviFileRef)
		end getModDate
		
		on setSrcSpecialFlag()
			if (typeset_command()) contains "-src" then
				set_src_special(true)
				ignoring application responses
					tell application "Finder"
						set comment of (dviFileRef) to "Source Specials"
					end tell
				end ignoring
			else
				set_src_special(false)
				ignoring application responses
					tell application "Finder"
						set comment of dviFileRef to ""
					end tell
				end ignoring
			end if
		end setSrcSpecialFlag
		
		on getSrcSpecialFlag()
			if src_special() is missing value then
				tell application "Finder"
					set theComment to comment of (dviFileRef)
				end tell
				set_src_special(theComment starts with "Source Special")
			end if
		end getSrcSpecialFlag
		
		on openDVI given activation:aFlag
			openDVI of DVIDriver given sender:a reference to me, activation:aFlag
		end openDVI
		
		on dviToPDF()
			--log "start dviToPDF"
			set thePDFObj to lookupPDFFile()
			--log "success lookupPDFFile"
			--check busy status of pdf file.
			if thePDFObj is not missing value then
				if not prepareDVItoPDF() of thePDFObj then
					return missing value
				end if
			end if
			
			--log "convert a DVI file into a PDF file"
			if (my dvipdfCommand is missing value) then
				set theCommand to contents of default entry "dvipdfCommand" of user defaults
			else
				set theCommand to my dvipdfCommand
			end if
			set cdCommand to "cd" & space & (quoted form of (pwd()'s posix_path()))
			set targetFileName to name_for_suffix(".dvi")
			set allCommand to cdCommand & comDelim & theCommand & space & "'" & targetFileName & "'"
			
			sendCommands of TerminalCommander for allCommand
			copy TerminalCommander to currentTerminal
			waitEndOfCommand(300) of currentTerminal
			
			if thePDFObj is missing value then
				set thePDFObj to lookupPDFFile()
			else
				if not (isExistPDF() of thePDFObj) then
					set thePDFObj to missing value
				end if
			end if
			
			--log "end of dviToPDF"
			return thePDFObj
		end dviToPDF
		
		on lookupPDFFile()
			--log "start lookupPDFFile"
			set thePDFObj to makeObj(a reference to me) of PDFObj
			setPDFObj() of thePDFObj
			if isExistPDF() of thePDFObj then
				return thePDFObj
			else
				return missing value
			end if
		end lookupPDFFile
	end script
	
	--log "before  setDVIDriver of DVIObj"
	setDVIDriver() of DviObj
	--log "end makeObj of DVIObj"
	return DviObj
end makeObj