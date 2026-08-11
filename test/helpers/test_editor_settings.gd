extends "res://addons/clyde/editor/config/editor_settings/clyde_editor_settings.gd"

var in_memory_settings: Dictionary = {}



func get_color_scheme_setting(key: String) -> Color:
	return Color(in_memory_settings.get(key))


func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant:
	return in_memory_settings.get(section, {}).get(key, default)


func set_project_metadata(section: String, key: String, data: Variant) -> void:
	if not in_memory_settings.has(section):
		in_memory_settings[section] = {}
	in_memory_settings[section][key] = data


func get_open_dialogues_paths() -> Array[String]:
	return []


func get_theme_icon(_icon_name: String) -> Texture2D:
	return load("res://addons/clyde/editor/assets/clyde.svg")
