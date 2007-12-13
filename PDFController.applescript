global UtilityHandlers
global PathAnalyzer
global DefaultsManager
global MessageUtility
global appController

property prePDFPreviewMode : 1 -- 0: open in Finder, 1: Preview.app, 2: Adobe Reader, 3: Acrobat
property pdfPreviewBox : missing value
property acrobatName : missing value
property acrobatPath : ""
property adobeReaderPath : ""
property hasAcrobat : false
property hasReader : false

on controlClicked(theObject)
	set theName to name of theObject
	if theName is "PDFPreview" then
		set theName to name of current cell of theObject
		--log theName
		if theName is "AdobeReader" then
			try
				findAdobeReaderApp()
			on error errMsg number -128
				set contents of default entry "PDFPreviewMode" of user defaults to prePDFPreviewMode
				set theMessage to localized string "PDFPreviewIsInvalid"
				showMessage(theMessage) of MessageUtility
				return
			end try
		else if theName is "Acrobat" then
			try
				findAcrobatApp()
			on error errMsg number -128
				set contents of default entry "PDFPreviewMode" of user defaults to prePDFPreviewMode
				set theMessage to localized string "PDFPreviewIsInvalid"
				showMessage(theMessage) of MessageUtility
				return
			end try
		end if
		
		set prePDFPreviewMode to default entry "PDFPreviewMode" of user defaults
		--set contents of default entry "PDFPreviewMode" of user defaults to PDFPreviewMode
	end if
end controlClicked

on findCARO() -- find acrobat or adobe reader from creator code
	try
		tell application "Finder"
			set caroApp to application file id "CARO"
		end tell
		return caroApp as alias
	on error
		return missing value
	end try
end findCARO

on findAcrobatApp()
	if class of acrobatPath is alias then
		return
	end if
	
	try
		set acrobatPath to (POSIX file acrobatPath) as alias
	on error
		set acrobatPath to findCARO()
	end try
	
	if acrobatPath is missing value then
		set theMessage to localized string "whereisAdobeAcrobat"
		set acrobatPath to choose application with prompt theMessage as alias
	else
		tell application "Finder"
			set theName to name of acrobatPath
		end tell
		if theName contains "Reader" then
			set acrobatPath to missing value
			set theMessage to localized string "whereisAdobeAcrobat"
			set acrobatPath to choose application with prompt theMessage as alias
		end if
	end if
	tell user defaults
		set contents of default entry "AcrobatPath" to acrobatPath
	end tell
end findAcrobatApp

on findAdobeReaderApp()
	--log "start findAdobeReaderApp"
	--log adobeReaderPath
	if class of adobeReaderPath is alias then
		return
	end if
	
	try
		set adobeReaderPath to (POSIX file adobeReaderPath) as alias
	on error
		set adobeReaderPath to findCARO()
	end try
	
	if adobeReaderPath is missing value then
		set theMessage to localized string "whereisAdobeReader"
		set adobeReaderPath to choose application with prompt theMessage as alias
	else
		tell application "Finder"
			set theName to name of adobeReaderPath
		end tell
		if theName does not contain "Reader" then
			set adobeReaderPath to missing value
			set theMessage to localized string "whereisAdobeReader"
			set adobeReaderPath to choose application with prompt theMessage as alias
		end if
	end if
	tell user defaults
		set contents of default entry "AdobeReaderPath" to adobeReaderPath
	end tell
	--log "end findAdobeReaderApp"
end findAdobeReaderApp

on checkPDFApp()
	set prePDFPreviewMode to contents of default entry "PDFPreviewMode" of user defaults
	if prePDFPreviewMode is 2 then
		try
			findAdobeReaderApp()
		on error errMsg number -128
			call method "revertToFactoryDefaultForKey:" of appController with parameter "PDFPreviewMode"
		end try
	else if prePDFPreviewMode is 3 then
		try
			findAcrobatApp()
		on error errMsg number -128
			call method "revertToFactoryDefaultForKey:" of appController with parameter "PDFPreviewMode"
		end try
	end if
	set prePDFPreviewMode to contents of default entry "PDFPreviewMode" of user defaults
end checkPDFApp

on loadSettings()
	set acrobatPath to readDefaultValueWith("AcrobatPath", acrobatPath) of DefaultsManager
	set adobeReaderPath to readDefaultValueWith("AdobeReaderPath", adobeReaderPath) of DefaultsManager
	--log "success read default value of PDFPreviewIndex"
	checkPDFApp()
end loadSettings

script GenericDriver
	on prepare(a_pdf)
		set isPDFBusy to busy status of fileInfo of a_pdf
		if isPDFBusy then
			try
				tell application (default application of fileInfo of a_pdf as Unicode text)
					close window pdfFileName of a_pdf
				end tell
				set isPDFBusy to busy status of (info for pdfAlias of a_pdf)
			end try
			
			if isPDFBusy then
				set a_msg to UtilityHandlers's localized_string("FileIsOpened", {pdfPath of a_pdf})
				EditorClient's show_message(a_msg)
				return false
			else
				return true
			end if
		else
			return true
		end if
	end prepare
	
	on openPDF(a_pdf)
		try
			tell application "Finder"
				open pdfAlias of a_pdf
			end tell
		on error errMsg number errNum
			activate
			display dialog errMsg buttons {"OK"} default button "OK"
		end try
	end openPDF
end script

script AcrobatDriver
	on prepare(a_pdf)
		--log "start prepare of AcrobatDriver"
		if isRunning(processName of a_pdf) of UtilityHandlers then
			tell application "System Events"
				set visible of application process (processName of a_pdf) to true
			end tell
			closePDFfile(a_pdf)
		else
			set pageNumber of a_pdf to missing value
		end if
		--log pageNumber of a_pdf
		--log "end prepare in AcrobatDriver"
		return true
	end prepare
	
	on closePDFfile(a_pdf)
		--log "start closePDFfile of AcrobatDriver"
		using terms from application "Adobe Acrobat 7.0 Standard"
			--log pdfFileName of a_pdf
			tell application ((appName of a_pdf) as Unicode text)
				if exists document (pdfFileName of a_pdf) then
					set theFileAliasPath to file alias of document (pdfFileName of a_pdf) as Unicode text
					if theFileAliasPath is (pdfAlias of a_pdf as Unicode text) then
						bring to front document (pdfFileName of a_pdf)
						set pageNumber of a_pdf to page number of PDF Window 1 of active doc
						--close PDF Window 1
						try
							close active doc
						on error
							delay 1
							close active doc
						end try
					end if
				else
					set pageNumber of a_pdf to missing value
				end if
			end tell
		end using terms from
		--log "end closePDFfile of AcrobatDriver"
	end closePDFfile
	
	on openPDF(a_pdf)
		--log "start openPDF in AcrobatDriver"
		using terms from application "Adobe Acrobat 7.0 Standard"
			tell application ((appName of a_pdf) as Unicode text)
				activate
				open pdfAlias of a_pdf
				if pageNumber of a_pdf is not missing value then
					set page number of PDF Window 1 of active doc to pageNumber of a_pdf
				end if
			end tell
		end using terms from
		--log "end openPDF in AcrobatDriver"
	end openPDF
end script

script PreviewDriver
	
	on prepare(a_pdf)
		if isRunning(processName of a_pdf) of UtilityHandlers then
			tell application "System Events"
				tell application process (processName of a_pdf)
					set windowNumber of a_pdf to count windows
				end tell
			end tell
		end if
		return true
	end prepare
	
	on openPDF(a_pdf)
		tell application (appName of a_pdf)
			open pdfAlias of a_pdf
		end tell
		
		if windowNumber of a_pdf is not missing value then
			tell application "System Events"
				tell application process (processName of a_pdf)
					set currentWinNumber to count windows
				end tell
			end tell
			
			activate application (appName of a_pdf)
			
			if windowNumber of a_pdf is currentWinNumber then
				tell application "System Events"
					tell application process (processName of a_pdf)
						set closeButton to buttons of window 1 whose subrole is "AXCloseButton"
						perform action "AXPress" of item 1 of closeButton
						--keystroke "w" using command down
					end tell
				end tell
				delay 1
				tell application (appName of a_pdf)
					open pdfAlias of a_pdf
				end tell
			end if
		else
			activate application (appName of a_pdf)
		end if
	end openPDF
end script

script AutoDriver
	
	on prepare(a_pdf)
		setTargetDriver(a_pdf)
		
		return prepare(a_pdf) of targetDriver of a_pdf
	end prepare
	
	on setTargetDriver(a_pdf)
		set defAppInfo to info for (default application of fileInfo of a_pdf)
		set theName to name of defAppInfo
		if theName ends with ".app" then
			set theName to text 1 thru -5 of theName
		end if
		
		if (file creator of defAppInfo) is "CARO" then
			if (theName) contains "Reader" then
				set targetDriver of a_pdf to PreviewDriver
				set processName of a_pdf to "Adobe Reader"
			else
				set targetDriver of a_pdf to AcrobatDriver
				if (package folder of defAppInfo) then
					set processName of a_pdf to "Acrobat"
				else
					set processName of a_pdf to theName
				end if
				
			end if
		else
			set targetDriver of a_pdf to PreviewDriver
			set processName of a_pdf to theName
		end if
		
		set appName of a_pdf to theName
		
	end setTargetDriver
	
	on openPDF(a_pdf)
		if targetDriver of a_pdf is missing value then
			setTargetDriver(a_pdf)
		end if
		openPDF(a_pdf) of targetDriver of a_pdf
	end openPDF
end script

on make_with(a_dvi)
	script PDFController
		property parent : a_dvi
		property aliasIsResolved : false
		property pdfFileName : missing value
		property pdfPath : missing value
		property pdfAlias : missing value
		property fileInfo : missing value
		
		property targetDriver : missing value
		property appName : missing value
		property processName : missing value -- used for PreviewDriver
		property windowNumber : missing value -- used for PreviewDriver
		property pageNumber : missing value -- used for AcrobatDriver
		
		property PDFDriver : AutoDriver
		
		on setPDFDriver()
			--log "start setPDFDriver()"
			set PDFPreviewMode to contents of default entry "PDFPreviewMode" of user defaults
			if PDFPreviewMode is 0 then
				set PDFDriver to AutoDriver
			else if PDFPreviewMode is 1 then
				--log "PreviewDriver is selected"
				set PDFDriver to PreviewDriver
				set processName to "Preview"
				set appName to "Preview"
			else if PDFPreviewMode is 2 then
				set PDFDriver to PreviewDriver
				set processName to "Adobe Reader"
				tell application "Finder"
					set appName to name of adobeReaderPath
				end tell
			else if PDFPreviewMode is 3 then
				set PDFDriver to AcrobatDriver
				set processName to "Acrobat"
				set appName to acrobatPath
			else
				error "PDF Preview Setting is invalid." number 1280
			end if
			--log "end of setPDFDriver()"
		end setPDFDriver
		
		on setup()
			set pdfFileName to name_for_suffix(".pdf")
			set pdfPath to pwd()'s child(pdfFileName)'s hfs_path()
		end setup
		
		on isExistPDF()
			try
				set pdfAlias to alias pdfPath
				set fileInfo to info for pdfAlias
				return true
			on error
				return false
			end try
			--return isExists(pdfPath of GenericDriver) of UtilityHandlers
		end isExistPDF
		
		on prepareDVItoPDF()
			return prepare(a reference to me) of PDFDriver
		end prepareDVItoPDF
		
		on openPDFFile()
			--log "start openPDFFile"
			openPDF(a reference to me) of PDFDriver
			--log "end openPDFFile"
		end openPDFFile
	end script
	setPDFDriver() of PDFController
	return PDFController
end make_with