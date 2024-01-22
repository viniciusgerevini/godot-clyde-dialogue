extends RefCounted

signal settings_changed

var _editor_settings: EditorSettings

const EDITOR_CFG_SHOW_LISTS = "show_lists"
const EDITOR_CFG_SHOW_PLAYER = "show_player"
const EDITOR_CFG_SYNC_PLAYER = "sync_player"
const EDITOR_CFG_PLAYER_SHOW_MULTI_BUBBLE = "player_multi_bubble"
const EDITOR_CFG_PLAYER_SHOW_METADATA = "player_metadata"


func _init():
	_editor_settings = EditorInterface.get_editor_settings()
	_editor_settings.settings_changed.connect(_on_settings_changed)


func _get_setting(key: String):
	return _editor_settings.get_setting(key)


func editor_settings():
	return {
		"auto_brace_completion_enabled": _get_setting("text_editor/completion/auto_brace_complete"),
		"auto_brace_completion_highlight_matching": _get_setting("text_editor/completion/auto_brace_complete"),
		"code_completion_enabled": _get_setting("text_editor/completion/code_complete_enabled"),
		"gutters_draw_line_numbers": _get_setting("text_editor/appearance/gutters/show_line_numbers"),
		"gutters_zero_pad_line_numbers": _get_setting("text_editor/appearance/gutters/line_numbers_zero_padded"),
		"line_length_guidelines": (
			[] if not _get_setting("text_editor/appearance/guidelines/show_line_length_guidelines")
			else [
				_get_setting("text_editor/appearance/guidelines/line_length_guideline_hard_column"),
				_get_setting("text_editor/appearance/guidelines/line_length_guideline_soft_column"),
			]
		),
		"indent_automatic": _get_setting("text_editor/behavior/indent/auto_indent"),
		"indent_size": _get_setting("text_editor/behavior/indent/size"),
		"indent_use_spaces": _get_setting("text_editor/behavior/indent/type") == 1, # couldn't find this enum
		"autowrap_mode": _get_setting("text_editor/appearance/lines/autowrap_mode"),
		"caret_blink": _get_setting("text_editor/appearance/caret/caret_blink"),
		"caret_blink_interval": _get_setting("text_editor/appearance/caret/caret_blink_interval"),
		#self.caret_move_on_right_click = settings.get_setting("")
		"caret_type": _get_setting("text_editor/appearance/caret/type"),
		"drag_and_drop_selection_enabled": _get_setting("text_editor/behavior/navigation/drag_and_drop_selection"),
		#self.draw_control_chars = settings.get_setting("")
		"draw_spaces": _get_setting("text_editor/appearance/whitespace/draw_spaces"),
		"draw_tabs": _get_setting("text_editor/appearance/whitespace/draw_tabs"),
		"highlight_current_line": _get_setting("text_editor/appearance/caret/highlight_current_line"),
		#self.middle_mouse_paste_enabled = settings.get_setting("")
		"minimap_draw": _get_setting("text_editor/appearance/minimap/show_minimap"),
		"minimap_width": _get_setting("text_editor/appearance/minimap/minimap_width"),
		"scroll_past_end_of_file": _get_setting("text_editor/behavior/navigation/scroll_past_end_of_file"),
		"scroll_smooth": _get_setting("text_editor/behavior/navigation/smooth_scrolling"),
		"scroll_v_scroll_speed": _get_setting("text_editor/behavior/navigation/v_scroll_speed"),
		"wrap_mode": _get_setting("text_editor/appearance/lines/word_wrap"),
	}


func editor_color_scheme():
	return {
		"background": _get_setting("text_editor/theme/highlighting/background_color"),
		"current_line": _get_setting("text_editor/theme/highlighting/current_line_color"),
		"error_line": _get_setting("text_editor/theme/highlighting/mark_color"),
		"comment": _get_setting("text_editor/theme/highlighting/comment_color"),
		"identifier": _get_setting("text_editor/theme/highlighting/member_variable_color"),
		"symbol": _get_setting("text_editor/theme/highlighting/symbol_color"),
		"text": _get_setting("text_editor/theme/highlighting/text_color"),
		"tag": _get_setting("text_editor/theme/highlighting/function_color"),
		"keyword": _get_setting("text_editor/theme/highlighting/keyword_color"),
		"operator": _get_setting("text_editor/theme/highlighting/control_flow_keyword_color"),
		"number_literal": _get_setting("text_editor/theme/highlighting/number_color"),
		"boolean_literal": _get_setting("text_editor/theme/highlighting/keyword_color"),
		"string_literal": _get_setting("text_editor/theme/highlighting/string_color"),
	}


func _on_settings_changed():
	settings_changed.emit()


func get_editor_config():
	return _editor_settings.get_project_metadata("clyde", "config", {})


func set_config(config_name: String, value):
	var config = get_editor_config()
	config[config_name] = value
	_editor_settings.set_project_metadata("clyde", "config", config)


func get_open_files():
	return _editor_settings.get_project_metadata("clyde", "open_files", [])


func set_open_files(open_files: Array):
	_editor_settings.set_project_metadata("clyde", "open_files", open_files)


func get_recents() -> Array:
	return _editor_settings.get_project_metadata("clyde", "recents", [])


func set_recents(recents: Array):
	_editor_settings.set_project_metadata("clyde", "recents", recents)


func add_recent(path: String):
	var recents = get_recents()
	if recents.has(path):
		recents.erase(path)
	elif recents.size() > 9:
		recents.remove_at(9)
	recents.push_front(path)
	set_recents(recents)


func clear_recents():
	set_recents([])
