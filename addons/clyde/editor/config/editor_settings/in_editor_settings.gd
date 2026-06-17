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
	"accent_color": "interface/theme/accent_color",
	"base_color": "interface/theme/base_color",
}

func _init():
	_editor_settings = EditorInterface.get_editor_settings()
	_editor_settings.settings_changed.connect(_on_settings_changed)


func get_setting(key: String) -> Variant:
	return _editor_settings.get_setting(_settings_map.get(key, key))


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
