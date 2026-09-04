##
## Clyde Editor Settings interface. This abstraction allows running the plugin code with
## different settings implementations.
## For example, in the plugin, it sources configurations from the editor and project setttings, while
## there is a demo that implements a different class that gets it's values from a configuration object
##
@abstract extends RefCounted

@abstract func get_color_scheme_setting(key: String) -> Color
@abstract func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant
@abstract func set_project_metadata(section: String, key: String, data: Variant) -> void
@abstract func get_theme_icon(icon_name: String) -> Texture2D
@abstract func get_open_dialogues_paths() -> Array[String]
