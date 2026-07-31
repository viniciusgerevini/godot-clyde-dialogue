##
## Clyde Editor Setting implementation to use in Godot Editor's plugin
##
extends "./clyde_editor_settings.gd"


var _editor_settings: EditorSettings

var _settings_map: Dictionary[String, String] = {
	"auto_brace_completion_enabled": "text_editor/completion/auto_brace_complete",
	"auto_brace_completion_highlight_matching": "text_editor/completion/auto_brace_complete",
	"code_completion_enabled": "text_editor/completion/code_complete_enabled",
	"gutters_draw_line_numbers": "text_editor/appearance/gutters/show_line_numbers",
	"gutters_zero_pad_line_numbers": "text_editor/appearance/gutters/line_numbers_zero_padded",
	"show_line_length_guidelines": "text_editor/appearance/guidelines/show_line_length_guidelines",
	"line_length_guideline_hard_column": "text_editor/appearance/guidelines/line_length_guideline_hard_column",
	"line_length_guideline_soft_column": "text_editor/appearance/guidelines/line_length_guideline_soft_column",
	"indent_automatic": "text_editor/behavior/indent/auto_indent",
	"indent_size": "text_editor/behavior/indent/size",
	"indent_use_spaces": "text_editor/behavior/indent/type",
	"autowrap_mode": "text_editor/appearance/lines/autowrap_mode",
	"caret_blink": "text_editor/appearance/caret/caret_blink",
	"caret_blink_interval": "text_editor/appearance/caret/caret_blink_interval",
	"caret_type": "text_editor/appearance/caret/type",
	"drag_and_drop_selection_enabled": "text_editor/behavior/navigation/drag_and_drop_selection",
	"draw_spaces": "text_editor/appearance/whitespace/draw_spaces",
	"draw_tabs": "text_editor/appearance/whitespace/draw_tabs",
	"highlight_current_line": "text_editor/appearance/caret/highlight_current_line",
	"minimap_draw": "text_editor/appearance/minimap/show_minimap",
	"minimap_width": "text_editor/appearance/minimap/minimap_width",
	"scroll_past_end_of_file": "text_editor/behavior/navigation/scroll_past_end_of_file",
	"scroll_smooth": "text_editor/behavior/navigation/smooth_scrolling",
	"scroll_v_scroll_speed": "text_editor/behavior/navigation/v_scroll_speed",
	"wrap_mode": "text_editor/appearance/lines/word_wrap",
	"font_size": "interface/editor/code_font_size",
	"background": "text_editor/theme/highlighting/background_color",
	"current_line": "text_editor/theme/highlighting/current_line_color",
	"error_line": "text_editor/theme/highlighting/mark_color",
	"comment": "text_editor/theme/highlighting/comment_color",
	"identifier": "text_editor/theme/highlighting/member_variable_color",
	"symbol": "text_editor/theme/highlighting/symbol_color",
	"text": "text_editor/theme/highlighting/text_color",
	"tag": "text_editor/theme/highlighting/function_color",
	"keyword": "text_editor/theme/highlighting/keyword_color",
	"operator": "text_editor/theme/highlighting/control_flow_keyword_color",
	"number_literal": "text_editor/theme/highlighting/number_color",
	"boolean_literal": "text_editor/theme/highlighting/keyword_color",
	"string_literal": "text_editor/theme/highlighting/string_color",
	"warning_color": "text_editor/theme/highlighting/comment_markers/warning_color",
	"success_color": "text_editor/theme/highlighting/safe_line_number_color",
	"error_color": "text_editor/theme/highlighting/mark_color",
}

var _interface_settings_map: Dictionary[String, String] = {
	"accent_color": "interface/theme/accent_color",
	"base_color": "interface/theme/base_color",
}

var _theme_icon_map: Dictionary[String, String] = {
	"status_success": "StatusSuccess",
	"status_error": "StatusError",
	"status_warning": "StatusWarning",
	"save": "Save",
	"edit": "Edit",
	"remove": "Remove",
	"close": "Close",
	"load": "Load",
	"dialogue_restart": "RotateLeft",
	"dialogue_next_line": "Play",
	"dialogue_forward": "TransitionEnd",
	"dialogue_clear_mem": "History",
	"dialogue_show_debug": "Debug",
	"menu_icon": "GuiTabMenu",
	"add_var": "Add",
	"progress_1": "Progress1",
	"progress_2": "Progress2",
	"progress_3": "Progress3",
	"progress_4": "Progress4",
	"progress_5": "Progress5",
	"progress_6": "Progress6",
	"progress_7": "Progress7",
	"progress_8": "Progress8",
	"autocomplete_block": "MoveRight",
	"autocomplete_block_end": "PickerShapeRectangleWheel",
	"autocomplete_variation": "KeyValue",
	"external_link": "ExternalLink",
	"help": "Info",
	"help_license": "ShaderDock",
	"help_editor": "Script",
	"help_player": "PlayScene",
	"help_debugger": "Debug",
	"help_tools": "Tools",
	"help_language": "AcceptDialog",
}


func _init():
	_editor_settings = EditorInterface.get_editor_settings()
	_editor_settings.settings_changed.connect(_on_settings_changed)


func get_setting(key: String) -> Variant:
	return _editor_settings.get_setting(_settings_map.get(key, key))


func get_interface_setting(key: String) -> Variant:
	return _editor_settings.get_setting(_interface_settings_map.get(key, key))


func get_color_scheme_setting(key: String) -> Color:
	return get_setting(key)


func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant:
	return _editor_settings.get_project_metadata(section, key, default)


func set_project_metadata(section: String, key: String, data: Variant) -> void:
	_editor_settings.set_project_metadata(section, key, data)


func _on_settings_changed():
	settings_changed.emit()


func get_interface_scale() -> float:
	return EditorInterface.get_editor_scale()


func change_font_size(offset: float):
	var f = _editor_settings.get_setting("interface/editor/code_font_size")
	_editor_settings.set_setting("interface/editor/code_font_size", (f + offset))


func clear_font_size():
	_editor_settings.set_setting("interface/editor/code_font_size", 14)


func get_open_dialogues_paths() -> Array[String]:
	# at the moment there is no better way to get open clyde files
	var editor_layout = ConfigFile.new()
	editor_layout.load("res://.godot/editor/editor_layout.cfg")
	var open_scripts: Array = editor_layout.get_value("ScriptEditor", "open_scripts")
	var clyde_files: Array[String] = []
	clyde_files.append_array(open_scripts)
	return clyde_files.filter(func (script: String): return script.ends_with(".clyde"))


func get_theme_icon(icon_name: String) -> Texture2D:
	if _theme_icon_map.has(icon_name):
		return EditorInterface.get_base_control().get_theme_icon(_theme_icon_map[icon_name], "EditorIcons")
	return load("res://addons/clyde/editor/assets/clyde.svg")
