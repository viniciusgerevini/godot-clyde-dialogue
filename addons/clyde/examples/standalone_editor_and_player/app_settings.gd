extends "res://addons/clyde/editor/config/editor_settings/clyde_editor_settings.gd"

# This is a sample custom config for the demo, implementing the interface defined in the plugin
# and basic functionality, like remembering players choice and saving stuff.
# Implementing something like this is optional. I just did it to reuse the plugin player and make
# this demo easier to keep in sync with the plugin

const CONFIG_PATH: String = "user://editor_settings.cfg"
const METADATA_PATH: String = "user://editor_cache.cfg"

const default_settings = {
	"auto_brace_completion_enabled": true,
	"auto_brace_completion_highlight_matching": true,
	"code_completion_enabled": true,
	"gutters_draw_line_numbers": true,
	"gutters_zero_pad_line_numbers": false,
	"line_length_guideline_hard_column": 100,
	"line_length_guideline_soft_column": 80,
	"indent_automatic": true,
	"indent_size": 4,
	"indent_use_spaces": false,
	"autowrap_mode": 3,
	"caret_blink": true,
	"caret_blink_interval": 0.5,
	"caret_type": 0,
	"drag_and_drop_selection_enabled": true,
	"draw_spaces": true,
	"draw_tabs": true,
	"highlight_current_line": true,
	"minimap_draw": true,
	"minimap_width": 80,
	"scroll_past_end_of_file": true,
	"scroll_smooth": true,
	"scroll_v_scroll_speed": 80,
	"wrap_mode": 0,
	"font_size": 14.0,
}

const DEFAUL_COLOR_SCHEME = {
	"background": "#1d2229ff",
	"current_line": "#ffffff12",
	"error_line": "#ff786b4d",
	"comment": "#cdcfd280",
	"identifier": "#bce0ffff",
	"symbol": "#abc9ffff",
	"text": "#cdcfd2ff",
	"tag": "#57b3ffff",
	"keyword": "#ff7085ff",
	"operator": "#ff8cccff",
	"number_literal": "#a1ffe0ff",
	"boolean_literal": "#ff7085ff",
	"string_literal": "#ffeda1ff",
	"warning_color": "#b89c7aff",
	"success_color": "#cdf8d2bf",
	"error_color": "#ff786b4d",
}

const default_interface_settings = {
	"accent_color": "#569effff",
	"base_color": "#272727",
	"scale": 1,
	"font_size": 14.0,
	"contrast": 0.3,
	"base_spacing": 4,
}

var _loaded_config: ConfigFile
var _loaded_cache: ConfigFile

const EDITOR_SECTION_KEY = "editor"
const WINDOW_SECTION_KEY = "window"

# To keep this demo consistent with the editor experience, the icons
# were sourced from https://github.com/godotengine/godot/tree/master/editor/icons
var _theme_icon_map: Dictionary[String, String] = {
	"dialogue_restart": "RotateLeft",
	"dialogue_next_line": "Play",
	"dialogue_forward": "TransitionEnd",
	"dialogue_clear_mem": "History",
	"dialogue_show_debug": "Debug",
	"menu_icon": "GuiTabMenu",
	"autocomplete_block": "MoveRight",
	"autocomplete_block_end": "PickerShapeRectangleWheel",
	"autocomplete_variation": "KeyValue",
}


func _init():
	_load_settings()
	_load_cache()


func get_setting(key: String) -> Variant:
	if key == 'font_size':
		return _get_current_font_size()
	return _get_setting(key)


func _get_setting(key: String) -> Variant:
	if _loaded_config.has_section_key("settings", key):
		return _loaded_config.get_value("settings", key, default_settings.get(key))
	return default_settings.get(key)


func get_interface_setting(key: String) -> Variant:
	if _loaded_config.has_section_key("interface_settings", key):
		return _loaded_config.get_value("interface_settings", key, default_interface_settings.get(key))
	return default_interface_settings.get(key)


func get_color_scheme_setting(key: String) -> Color:
	return Color(DEFAUL_COLOR_SCHEME[key])


func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant:
	if _loaded_cache.has_section_key(section, key):
		return _loaded_cache.get_value(section, key, default)
	return default


func set_project_metadata(section: String, key: String, data: Variant) -> void:
	_loaded_cache.set_value(section, key, data)
	var err = _loaded_cache.save(METADATA_PATH)
	if err != OK:
		print("Failed to persist editor cache")


func get_interface_scale() -> float:
	return get_interface_setting("scale")


func change_font_size(offset: float) -> void:
	var font_size = _get_current_font_size()
	set_project_metadata(EDITOR_SECTION_KEY, "font_size", font_size + offset)
	settings_changed.emit()


func clear_font_size() -> void:
	if _loaded_cache.has_section_key(EDITOR_SECTION_KEY, "font_size"):
		_loaded_cache.erase_section_key(EDITOR_SECTION_KEY, "font_size")
		settings_changed.emit()


func _get_current_font_size() -> float:
	return get_project_metadata(EDITOR_SECTION_KEY, "font_size", _get_setting("font_size"))


func _load_settings() -> void:
	_loaded_config = ConfigFile.new()
	var err = _loaded_config.load(CONFIG_PATH)

	if err != OK:
		print("Could not open settings file. Using defaults.")
		return


func _load_cache() -> void:
	_loaded_cache = ConfigFile.new()
	var err = _loaded_cache.load(METADATA_PATH)

	if err != OK:
		return


func get_open_dialogues_paths() -> Array[String]:
	return []


func get_theme_icon(icon_name: String) -> Texture2D:
	return load("res://addons/clyde/examples/standalone_editor_and_player/icons/%s.svg" % _theme_icon_map[icon_name])
