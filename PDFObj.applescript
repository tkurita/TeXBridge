global UtilityHandlers
global PathAnalyzer
global DefaultsManager

property PDFPreviewIndex : 1 -- 1: open in Finder, 2: Preview.app, 3: Adobe Reader, 4: Acrobat
property pdfPreviewBox : missing value
property defaultProcessName : missing value
property defaultAppName : missing value
property acrobatName : missing value
property acrobatPath : ""
property adobeReaderPath : ""
property hasAcrobat : false
property hasReader : false

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

on loadSettings()
	set PDFPreviewIndex to (readDefaultValue("PDFPreviewIndex") of DefaultsManager) as integer
	set acrobatPath to readDefaultValueWith("AcrobatPath", acrobatPath) of DefaultsManager
	set adobeReaderPath to readDefaultValueWith("AdobeReaderPath", adobeReaderPath) of DefaultsManager
	--log "success read default value of PDFPreviewIndex"
	if PDFPreviewIndex is 3 then
		try
			findAdobeReaderApp()
		on error errMsg number -128
			set PDFPreviewIndex to 1
		end try
	else if PDFPreviewIndex is 4 then
		try
			findAcrobatApp()
		on error errMsg number -128
			set PDFPreviewIndex to 1
		end try
	end if
	
	(*
	try
		tell application "Finder"
			set acrobatName to name of application file id "CARO"
		end tell
		if acrobatName contains "Reader" then
			set hasReader to true
		else
			set hasAcrobat to true
		end if
	end try
	*)
	setPDFDriver()
end loadSettings

on writeSettings()
	tell user defaults
		set contents of default entry "PDFPreviewIndex" to PDFPreviewIndex
	end tell
end writeSettings

on saveSettingsFromWindow() -- get all values from and window and save into preference	
	--log "start of saveSettingsFromWindow of PDFObj"
	set PDFPreviewIndex to current row of matrix "PDFPreview" of pdfPreviewBox
	--log "success get value of PDFPreviewIndex"
	writeSettings()
	setPDFDriver()
end saveSettingsFromWindow

on setSettingToWindow()
	--log "PDFPreviewIndex : " & PDFPreviewIndex
	set current row of matrix "PDFPreview" of pdfPreviewBox to PDFPreviewIndex
	--log "current row of matrix PDFPreview"
	--log (current row of matrix "PDFPreview" of pdfPreviewBox) as string
	--set enabled of cell "Acrobat" of matrix "PDFPreview" of pdfPreviewBox to hasAcrobat
	--set enabled of cell "AdobeReader" of matrix "PDFPreview" of pdfPreviewBox to hasReader
end setSettingToWindow

script GenericDriver
	on prepare(thePDFObj)
		set isPDFBusy to busy status of fileInfo of thePDFObj
		if isPDFBusy then
			try
				tell application (default application of fileInfo of thePDFObj as Unicode text)
					close window pdfFileName of thePDFObj
				end tell
				set isPDFBusy to busy status of (info for pdfAlias of thePDFObj)
			end try
			
			if isPDFBusy then
				set openedMessage to localized string "OpenedMessage"
				set theMessage to (pdfPath of thePDFObj) & return & openedMessage
				showMessageOnmi(theMessage) of MessageUtility
				return false
			else
				return true
			end if
		else
			return true
		end if
	end prepare
	
	on openPDF(thePDFObj)
		try
			tell application "Finder"
				open pdfAlias of thePDFObj
			end tell
		on error errMsg number errNum
			activate
			display dialog errMsg buttons {"OK"} default button "OK"
		end try
	end openPDF
end script

script AcrobatDriver
	on prepare(thePDFObj)
		--log "start prepare of AcrobatDriver"
		if isRunning(processName of thePDFObj) of UtilityHandlers then
			tell application "System Events"
				set visible of application process (processName of thePDFObj) to true
			end tell
			closePDFfile(thePDFObj)
		else
			set pageNumber of thePDFObj to missing value
		end if
		return true
	end prepare
	
	on closePDFfile(thePDFObj)
		--log "start closePDFfile of AcrobatDriver"
		using terms from application "Adobe Acrobat 7.0 Standard"
			--log pdfFileName of thePDFObj
			tell application ((appName of thePDFObj) as Unicode text)
				if exists document (pdfFileName of thePDFObj) then
					set theFileAliasPath to file alias of document (pdfFileName of thePDFObj) as Unicode text
					if theFileAliasPath is (pdfAlias of thePDFObj as Unicode text) then
						bring to front document (pdfFileName of thePDFObj)
						set pageNumber of thePDFObj to page number of PDF Window 1
						--close PDF Window 1
						try
							close active doc
						on error
							delay 1
							close active doc
						end try
					end if
				else
					set pageNumber of thePDFObj to missing value
				end if
			end tell
		end using terms from
	end closePDFfile
	
	on openPDF(thePDFObj)
		using terms from application "Adobe Acrobat 7.0 Standard"
			tell application ((appName of thePDFObj) as Unicode text)
				activate
				open pdfAlias of thePDFObj
				if pageNumber of thePDFObj is not missing value then
					set page number of PDF Window 1 to pageNumber of thePDFObj
				end if
			end tell
		end using terms from
	end openPDF
end script

script PreviewDriver
	
	on prepare(thePDFObj)
		if isRunning(processName of thePDFObj) of UtilityHandlers then
			tell application "System Events"
				tell application process (processName of thePDFObj)
					set windowNumber of thePDFObj to count windows
				end tell
			end tell
		end if
		return true
	end prepare
	
	on openPDF(thePDFObj)
		tell application (appName of thePDFObj)
			open pdfAlias of thePDFObj
		end tell
		
		if windowNumber of thePDFObj is not missing value then
			tell application "System Events"
				tell application process (processName of thePDFObj)
					set currentWinNumber to count windows
				end tell
			end tell
			
			activate application (appName of thePDFObj)
			
			if windowNumber of thePDFObj is currentWinNumber then
				tell application "System Events"
					tell application process (processName of thePDFObj)
						keystroke "w" using command down
					end tell
				end tell
				delay 1
				tell application (appName of thePDFObj)
					open pdfAlias of thePDFObj
				end tell
			end if
		else
			activate application (appName of thePDFObj)
		end if
	end openPDF
end script

script AutoDriver
	
	on prepare(thePDFObj)
		setTargetDriver(thePDFObj)
		
		return prepare(thePDFObj) of targetDriver of thePDFObj
	end prepare
	
	on setTargetDriver(thePDFObj)
		set defAppInfo to info for (default application of fileInfo of thePDFObj)
		set theName to name of defAppInfo
		if theName ends with ".app" then
			set theName to text 1 thru -5 of theName
		end if
		
		if (file creator of defAppInfo) is "CARO" then
			if (theName) contains "Reader" then
				set targetDriver of thePDFObj to PreviewDriver
				set processName of thePDFObj to "Adobe Reader"
			else
				set targetDriver of thePDFObj to AcrobatDriver
				if (package folder of defAppInfo) then
					set processName of thePDFObj to "Acrobat"
				else
					set processName of thePDFObj to theName
				end if
				
			end if
		else
			set targetDriver of thePDFObj to PreviewDriver
			set processName of thePDFObj to theName
		end if
		
		set appName of thePDFObj to theName
		
	end setTargetDriver
	
	on openPDF(thePDFObj)
		if targetDriver of thePDFObj is missing value then
			setTargetDriver(thePDFObj)
		end if
		openPDF(thePDFObj) of targetDriver of thePDFObj
	end openPDF
end script

property PDFDriver : AutoDriver

on setPDFDriver()
	--log "start setPDFDriver()"
	if PDFPreviewIndex is 1 then
		set PDFDriver to AutoDriver
	else if PDFPreviewIndex is 2 then
		--log "PreviewDriver is selected"
		set PDFDriver to PreviewDriver
		set defaultProcessName to "Preview"
		set defaultAppName to "Preview"
	else if PDFPreviewIndex is 3 then
		set PDFDriver to PreviewDriver
		set defaultProcessName to "Adobe Reader"
		tell application "Finder"
			set defaultAppName to name of adobeReaderPath
		end tell
	else if PDFPreviewIndex is 4 then
		set PDFDriver to AcrobatDriver
		set defaultProcessName to "Acrobat"
		set defaultAppName to acrobatPath
	end if
	--log "end of setPDFDriver()"
end setPDFDriver

on makeObj(theDviObj)
	script PDFObj
		property parent : theDviObj
		property aliasIsResolved : false
		property pdfFileName : missing value
		property pdfPath : missing value
		property pdfAlias : missing value
		property fileInfo : missing value
		
		property targetDriver : missing value
		property appName : defaultAppName
		property processName : defaultProcessName -- used for PreviewDriver
		property windowNumber : missing value -- used for PreviewDriver
		property pageNumber : missing value -- used for AcrobatDriver
		
		on setPDFObj()
			set pdfFileName to getNameWithSuffix(".pdf")
			set pdfPath to ((my workingDirectory) as Unicode text) & pdfFileName
		end setPDFObj
		
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
			openPDF(a reference to me) of PDFDriver
		end openPDFFile
	end script
	
	return PDFObj
end makeObj