##
## Clyde Editor Settings implementation to use in Godot Editor's plugin
##
extends "./clyde_editor_settings.gd"

var _editor_settings: EditorSettings

var _settings_map: Dictionary[String, String] = {
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


func _get_setting(key: String) -> Variant:
	return _editor_settings.get_setting(_settings_map.get(key, key))


func get_color_scheme_setting(key: String) -> Color:
	return _get_setting(key)


func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant:
	return _editor_settings.get_project_metadata(section, key, default)


func set_project_metadata(section: String, key: String, data: Variant) -> void:
	_editor_settings.set_project_metadata(section, key, data)


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
