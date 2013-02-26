property _window_controller : missing value
property _window : missing value

on window_controller()
	return my _window_controller
end window_controller

on stop_timer()
	if my _window_controller is not missing value then
		call method "temporaryStopReloadTimer" of my _window_controller
	end if
end stop_timer

on restart_timer()
	if my _window_controller is not missing value then
		call method "restartReloadTimer" of my _window_controller
	end if
end restart_timer

on is_visible()
	if my _window_controller is missing value then
		return false
	end if
	return visible of my _window
end is_visible

on rebuild_labels_from_aux(a_texdoc)
	-- log "start rebuild_labels_from_aux in RefPanelController"
	if my _window_controller is missing value then
		return
	end if
	if is_opened_expanded() then
		set tex_file_path to a_texdoc's tex_file()'s posix_path()
		call method "rebuildLabelsFromAux:textEncoding:" of my _window_controller Å 
			with parameters {tex_file_path, a_texdoc's text_encoding()}
		--rebuild_labels_from_aux(a_texdoc) of LabelListController
	end if
end rebuild_labels_from_aux


on initilize()
	--log "start initialize in RefPanelController"
	set my _window_controller to call method "alloc" of class "NewRefPanelController"
	set my _window_controller to call method "initWithWindowNibName:" of my _window_controller with parameter "NewReferencePalette"
	set my _window to call method "window" of my _window_controller
	call method "retain" of my _window
	--log "end initialize in RefPanelController"
end initilize

on open_window()
	--log "start open_window in RefPanelController"
	if my _window_controller is missing value then
		initilize()
	end if
	call method "showWindow:" of my _window_controller
	--log "end open_window in RefPanelController"
end open_window

on is_opened()
	if my _window_controller is missing value then
		return false
	end if
	set a_result to call method "isOpened" of my _window_controller
	return (a_result is 1)
end is_opened

on is_opened_expanded()
	if not is_opened() then
		return false
	end if
	
	set a_result to call method "isCollapsed" of my _window_controller
	return (a_result is not 1)
end is_opened_expanded

