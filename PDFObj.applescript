global UtilityHandlers
global PathAnalyzer

script GenericDriver
	property pdfFileName : missing value
	property fileInfo : missing value
	property pdfAlias : missing value
	property pdfPath : missing value
	
	on setup()
		set pdfAlias to alias pdfPath
		set fileInfo to info for pdfAlias
	end setup
	
	on prepare()
		set isPDFBusy to busy status of fileInfo
		if isPDFBusy then
			try
				tell application (default application of fileInfo as Unicode text)
					close window pdfFileName
				end tell
				set isPDFBusy to busy status of (info for pdfAlias)
			end try
			
			if isPDFBusy then
				set openedMessage to localized string "OpenedMessage"
				set theMessage to pdfPath & return & openedMessage
				showMessageOnmi(theMessage) of MessageUtility
				return false
			else
				return true
			end if
		else
			return true
		end if
	end prepare
	
	on openPDF()
		try
			tell application "Finder"
				open pdfAlias
			end tell
		on error errMsg number errNum
			activate
			display dialog errMsg buttons {"OK"} default button "OK"
		end try
	end openPDF
end script

script AcrobatDriver
	property parent : GenericDriver
	property appName : missing value
	property pageNumber : missing value
	
	on prepare()
		if isRunning(appName) of UtilityHandlers then
			closePDFfile()
		else
			set pageNumber to missing value
		end if
	end prepare
	
	on closePDFfile()
		set pageNumber to missing value
		using terms from application "Acrobat 6.0 Standard"
			tell application appName
				if exists document (my pdfFileName) then
					set theFileAliasPath to file alias of document (my pdfFileName) as Unicode text
					if theFileAliasPath is (pdfAlias as Unicode text) then
						bring to front document (my pdfFileName)
						set pageNumber to page number of PDF Window 1
						close PDF Window 1
					end if
				else
					set pageNumber to missing value
				end if
			end tell
		end using terms from
	end closePDFfile
	
	on openPDF()
		using terms from application "Acrobat 6.0 Standard"
			tell application appName
				open my pdfAlias
				if pageNumber is not missing value then
					set page number of PDF Window 1 to pageNumber
					set pageNaumber to missing value
				end if
			end tell
		end using terms from
	end openPDF
end script

script PreviewDriver
	property parent : GenericDriver
	property windowNumber : missing value
	property appName : missing value
	property processName : missing value
	
	on prepare()
		if isRunning(processName) of UtilityHandlers then
			log "process is running"
			tell application "System Events"
				tell application process processName
					set windowNumber to count windows
				end tell
			end tell
		end if
		return true
	end prepare
	
	on openPDF()
		tell application appName
			open my pdfAlias
		end tell
		if windowNumber is not missing value then
			tell application "System Events"
				tell application process processName
					set currentWinNumber to count windows
				end tell
			end tell
			activate application appName
			if windowNumber is currentWinNumber then
				tell application "System Events"
					tell application process processName
						keystroke "w" using command down
					end tell
				end tell
				delay 1
				tell application appName
					open my pdfAlias
				end tell
			end if
		end if
		set windowNumber to missing value
	end openPDF
end script

script AutoDriver
	property parent : GenericDriver
	property targetDriver : missing value
	
	on prepare()
		setTargetDriver()
		
		return prepare() of targetDriver
	end prepare
	
	on setTargetDriver()
		set defAppPath to (default application of my fileInfo) as Unicode text
		
		if defAppPath ends with "Acrobat 6.0 Standard.app:" then
			set targetDriver to AcrobatDriver
			set appName of targetDriver to "Acrobat"
		else if defAppPath ends with "Acrobat 6.0 Professional.app:" then
			set targetDriver to AcrobatDriver
			set appName of targetDriver to "Acrobat"
		else if defAppPath ends with "Acrobat 6.0 Elements.app:" then
			set targetDriver to AcrobatDriver
			set appName of targetDriver to "Acrobat"
		else if defAppPath ends with "Acrobat 5.0" then
			set targetDriver to AcrobatDriver
			set appName of targetDriver to "Acrobat 5.0"
		else
			set targetDriver to PreviewDriver
			
			set pathRecord to do(defAppPath) of PathAnalyzer
			set theName to name of pathRecord
			if theName starts with "Adobe Reader" then
				set processName of targetDriver to "Adobe Reader"
			else if theName ends with ".app" then
				set theName to text 1 thru -5 of theName
				set processName of targetDriver to theName
			end if
			
			set appName of targetDriver to theName
			--set targetDriver to GenericDriver
		end if
	end setTargetDriver
	
	on openPDF()
		if targetDriver is missing value then
			setTargetDriver()
		end if
		openPDF() of targetDriver
		set targetDriver to missing value
	end openPDF
end script

property PDFDriver : AutoDriver

on makeObj(theDviObj)
	script PDFObj
		property parent : theDviObj
		property aliasIsResolved : false
		
		on setPDFObj()
			set pdfFileName of GenericDriver to getNameWithSuffix(".pdf")
			set pdfPath of GenericDriver to (((my workingDirectory) as Unicode text) & pdfFileName of GenericDriver)
		end setPDFObj
		
		on isExistPDF()
			try
				setup() of GenericDriver
				return true
			on error
				return false
			end try
			--return isExists(pdfPath of GenericDriver) of UtilityHandlers
		end isExistPDF
		
		on prepareDVItoPDF()
			
			return prepare() of PDFDriver
		end prepareDVItoPDF
		
		on openPDFFile()
			openPDF() of PDFDriver
		end openPDFFile
	end script
	
	return PDFObj
end makeObj