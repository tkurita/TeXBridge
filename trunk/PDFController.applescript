global UtilityHandlers
global DefaultsManager
global MessageUtility
global appController

property _prePDFPreviewMode : 1 -- 0: open in Finder, 1: Preview.app, 2: Adobe Reader, 3: Acrobat
property _pdfPreviewBox : missing value
property _acrobatPath : ""
property _adobeReaderPath : ""
property _hasAcrobat : false -- not used ?
property _hasReader : false -- not used ?

on control_clicked(theObject)
	set a_name to name of theObject
	if a_name is "PDFPreview" then
		set a_name to name of current cell of theObject
		--log a_name
		if a_name is "AdobeReader" then
			try
				find_adobe_reader()
			on error msg number -128
				set contents of default entry "PDFPreviewMode" of user defaults to my _prePDFPreviewMode
				set a_msg to localized string "PDFPreviewIsInvalid"
				show_message(a_msg) of MessageUtility
				return
			end try
		else if a_name is "Acrobat" then
			try
				find_acrobat()
			on error msg number -128
				set contents of default entry "PDFPreviewMode" of user defaults to my _prePDFPreviewMode
				set a_msg to localized string "PDFPreviewIsInvalid"
				show_message(a_msg) of MessageUtility
				return
			end try
		end if
		
		set my _prePDFPreviewMode to default entry "PDFPreviewMode" of user defaults
		--set contents of default entry "PDFPreviewMode" of user defaults to PDFPreviewMode
	end if
end control_clicked

on find_caro() -- find acrobat or adobe reader from creator code
	try
		tell application "Finder"
			set a_caro to application file id "CARO"
		end tell
		return a_caro as alias
	on error
		return missing value
	end try
end find_caro

on find_acrobat()
	if class of _acrobatPath is alias then
		return
	end if
	
	try
		set _acrobatPath to (POSIX file _acrobatPath) as alias
	on error
		set _acrobatPath to find_caro()
	end try
	
	if _acrobatPath is missing value then
		set a_msg to localized string "whereisAdobeAcrobat"
		set _acrobatPath to choose application with prompt a_msg as alias
	else
		tell application "Finder"
			set a_name to name of _acrobatPath
		end tell
		if a_name contains "Reader" then
			set _acrobatPath to missing value
			set a_msg to localized string "whereisAdobeAcrobat"
			set _acrobatPath to choose application with prompt a_msg as alias
		end if
	end if
	tell user defaults
		set contents of default entry "AcrobatPath" to _acrobatPath
	end tell
end find_acrobat

on find_adobe_reader()
	--log "start find_adobe_reader"
	--log _adobeReaderPath
	if class of _adobeReaderPath is alias then
		return
	end if
	
	try
		set _adobeReaderPath to (POSIX file _adobeReaderPath) as alias
	on error
		set _adobeReaderPath to find_caro()
	end try
	
	if _adobeReaderPath is missing value then
		set a_msg to localized string "whereisAdobeReader"
		set _adobeReaderPath to choose application with prompt a_msg as alias
	else
		tell application "Finder"
			set a_name to name of _adobeReaderPath
		end tell
		if a_name does not contain "Reader" then
			set _adobeReaderPath to missing value
			set a_msg to localized string "whereisAdobeReader"
			set _adobeReaderPath to choose application with prompt a_msg as alias
		end if
	end if
	tell user defaults
		set contents of default entry "AdobeReaderPath" to _adobeReaderPath
	end tell
	--log "end find_adobe_reader"
end find_adobe_reader

on checkPDFApp()
	set _prePDFPreviewMode to contents of default entry "PDFPreviewMode" of user defaults
	if _prePDFPreviewMode is 2 then
		try
			find_adobe_reader()
		on error msg number -128
			call method "revertToFactoryDefaultForKey:" of appController with parameter "PDFPreviewMode"
		end try
	else if _prePDFPreviewMode is 3 then
		try
			find_acrobat()
		on error msg number -128
			call method "revertToFactoryDefaultForKey:" of appController with parameter "PDFPreviewMode"
		end try
	end if
	set _prePDFPreviewMode to contents of default entry "PDFPreviewMode" of user defaults
end checkPDFApp

on load_settings()
	set acrobatPath to value_with_default("AcrobatPath", _acrobatPath) of DefaultsManager
	set _adobeReaderPath to value_with_default("AdobeReaderPath", _adobeReaderPath) of DefaultsManager
	--log "success read default value of PDFPreviewIndex"
	checkPDFApp()
end load_settings

on target_driver()
	return my _target_driver
end target_driver

on set_target_driver(a_driver)
	set my _target_driver to a_driver
end set_target_driver

on file_hfs_path()
	return my _pdffile's hfs_path()
end file_hfs_path

on file_info()
	return my _pdffile's re_info()
end file_info

on file_as_alias()
	return my _pdffile's as_alias()
end file_as_alias

on window_counts()
	return my _window_counts
end window_counts

on set_window_counts(a_num)
	set my _window_counts to a_num
end set_window_counts

on app_name()
	return my _app_name
end app_name

on app_identifier()
	return my _app_identifier
end app_identifier

on set_app_name(a_name)
	set my _app_name to a_name
end set_app_name

on page_number()
	return my _page_number
end page_number

on set_page_number(a_num)
	set my _page_number to a_num
end set_page_number

on set_process_name(a_name)
	set my _process_name to a_name
end set_process_name

on process_name()
	return my _process_name
end process_name

on file_ref()
	return my _pdffile
end file_ref

on fileName()
	return my _pdffile's item_name()
end fileName

on setup_pdfdriver()
	--log "start setup_pdfdriver()"
	set PDFPreviewMode to contents of default entry "PDFPreviewMode" of user defaults
	if PDFPreviewMode is 0 then
		set my _pdfdriver to my AutoDriver
	else if PDFPreviewMode is 1 then
		--log "PreviewDriver is selected"
		set my _pdfdriver to my ReloadablePreviewDriver
		set my _process_name to "Preview"
		set my _app_name to "Preview"
		set my _app_identifier to "com.apple.Preview"
	else if PDFPreviewMode is 2 then
		set my _pdfdriver to my PreviewDriver
		set my _process_name to "Adobe Reader"
		tell application "Finder"
			set my _app_name to name of _adobeReaderPath
		end tell
	else if PDFPreviewMode is 3 then
		set my _pdfdriver to my AcrobatDriver
		set my _process_name to "Acrobat"
		set my _app_name to _acrobatPath
	else
		error "PDF Preview Setting is invalid." number 1280
	end if
	--log "end of setup_pdfdriver()"
end setup_pdfdriver

on setup()
	set my _pdffile to my _dvi's file_ref()'s change_path_extension("pdf")
end setup

on file_exists()
	return my _pdffile's item_exists()
end file_exists

on prepare_dvi_to_pdf()
	return prepare(a reference to me) of my _pdfdriver
end prepare_dvi_to_pdf

on open_pdf()
	--log "start open_pdf"
	open_pdf(a reference to me) of my _pdfdriver
	--log "end open_pdf"
end open_pdf

on make_with(a_dvi)
	script PDFController
		property _dvi : a_dvi
		property _pdffile : missing value
		property _target_driver : missing value -- used when _pdifdrive is AutoDriver
		property _app_name : missing value
		property _process_name : missing value -- used for PreviewDriver
		property _app_identifier : missing value -- used for ReloadablePreviewDriver
		property _window_counts : missing value -- used for PreviewDriver
		property _page_number : missing value -- used for AcrobatDriver
		
		property _pdfdriver : my AutoDriver
	end script
	
	PDFController's setup_pdfdriver()
	return PDFController
end make_with

script GenericDriver
	on prepare(a_pdf)
		set an_info to a_pdf's file_info()
		set is_file_busy to busy status of an_info
		if is_file_busy then
			try
				tell application (default application of an_info as Unicode text)
					close window name of an_info
				end tell
				set is_file_busy to busy status of (a_pdf's file_info())
			end try
			
			if is_file_busy then
				set a_msg to UtilityHandlers's localized_string("FileIsOpened", {a_pdf's file_hfs_path()})
				EditorClient's show_message(a_msg)
				return false
			else
				return true
			end if
		else
			return true
		end if
	end prepare
	
	on open_pdf(a_pdf)
		try
			tell application "Finder"
				open a_pdf's file_as_alias()
			end tell
		on error msg number errno
			activate
			display dialog msg buttons {"OK"} default button "OK"
		end try
	end open_pdf
end script

script AcrobatDriver
	on prepare(a_pdf)
		--log "start prepare of AcrobatDriver"
		set a_processname to a_pdf's process_name()
		if UtilityHandlers's is_running(a_processname) then
			tell application "System Events"
				set visible of application process (a_processname) to true
			end tell
			close_pdf(a_pdf)
		else
			a_pdf's set_page_number(missing value)
		end if
		--log _page_number of a_pdf
		--log "end prepare in AcrobatDriver"
		return true
	end prepare
	
	on close_pdf(a_pdf)
		--log "start close_pdf of AcrobatDriver"
		set a_filename to a_pdf's fileName()
		using terms from application "Adobe Acrobat Professional"
			tell application ((a_pdf's app_name()) as Unicode text)
				if exists document a_filename then
					set theFileAliasPath to file alias of document a_filename as Unicode text
					if theFileAliasPath is (a_pdf's file_hfs_path()) then
						bring to front document a_filename
						a_pdf's set_page_number(page number of PDF Window 1 of active doc)
						--close PDF Window 1
						try
							close active doc
						on error
							delay 1
							close active doc
						end try
					end if
				else
					a_pdf's set_page_number(missing value)
				end if
			end tell
		end using terms from
		--log "end close_pdf of AcrobatDriver"
	end close_pdf
	
	on open_pdf(a_pdf)
		--log "start open_pdf in AcrobatDriver"
		using terms from application "Adobe Acrobat Professional"
			tell application ((a_pdf's app_name()) as Unicode text)
				activate
				open a_pdf's file_as_alias()
				if a_pdf's page_number() is not missing value then
					a_pdf's set_page_number(page number of PDF Window 1 of active doc)
				end if
			end tell
		end using terms from
		--log "end open_pdf in AcrobatDriver"
	end open_pdf
end script

script ReloadablePreviewDriver
	
	on prepare(a_pdf)
		return true
	end prepare
	
	on open_pdf(a_pdf)
		set an_id to a_pdf's app_identifier()
		tell application id (an_id)
			open a_pdf's file_as_alias()
		end tell
		call method "activateAppOfIdentifier:" of class "SmartActivate" with parameter an_id
	end open_pdf
end script

script PreviewDriver
	
	on prepare(a_pdf)
		if is_running(a_pdf's process_name()) of UtilityHandlers then
			tell application "System Events"
				tell application process (a_pdf's process_name())
					a_pdf's set_window_counts(count windows)
				end tell
			end tell
		end if
		return true
	end prepare
	
	on open_pdf(a_pdf)
		tell application (a_pdf's app_name())
			open a_pdf's file_as_alias()
		end tell
		
		if a_pdf's window_counts() is not missing value then
			tell application "System Events"
				tell application process (a_pdf's process_name())
					set current_win_counts to count windows
				end tell
			end tell
			
			activate application (a_pdf's app_name())
			
			if a_pdf's window_counts() is current_win_counts then
				tell application "System Events"
					tell application process (a_pdf's process_name())
						set closeButton to buttons of window 1 whose subrole is "AXCloseButton"
						perform action "AXPress" of item 1 of closeButton
						--keystroke "w" using command down
					end tell
				end tell
				delay 1
				tell application (a_pdf's app_name())
					open a_pdf's file_as_alias()
				end tell
			end if
		else
			activate application (a_pdf's app_name())
		end if
	end open_pdf
end script

script AutoDriver
	on prepare(a_pdf)
		setup_target_driver(a_pdf)
		return a_pdf's target_driver()'s prepare(a_pdf)
	end prepare
	
	on setup_target_driver(a_pdf)
		set app_info to info for (default application of (a_pdf's file_info()))
		set a_name to name of app_info
		if a_name ends with ".app" then
			set a_name to text 1 thru -5 of a_name
		end if
		
		if (file creator of app_info) is "CARO" then
			if (a_name) contains "Reader" then
				a_pdf's set_target_driver(PreviewDriver)
				a_pdf's set_process_name("Adobe Reader")
			else
				a_pdf's set_target_driver(AcrobatDriver)
				if (package folder of app_info) then
					a_pdf's set_process_name("Acrobat")
				else
					a_pdf's set_process_name(a_name)
				end if
				
			end if
		else
			a_pdf's set_target_driver(PreviewDriver)
			a_pdf's set_process_name(a_name)
		end if
		
		a_pdf's set_app_name(a_name)
		
	end setup_target_driver
	
	on open_pdf(a_pdf)
		if a_pdf's target_driver() is missing value then
			setup_target_driver(a_pdf)
		end if
		a_pdf's target_driver()'s open_pdf(a_pdf)
	end open_pdf
end script
