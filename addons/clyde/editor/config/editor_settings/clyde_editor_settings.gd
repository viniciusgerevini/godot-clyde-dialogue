@abstract extends RefCounted

signal settings_changed

@abstract func get_setting(key: String) -> Variant
@abstract func get_color_scheme_setting(key: String) -> Color
@abstract func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant
@abstract func set_project_metadata(section: String, key: String, data: Variant) -> void
@abstract func get_interface_scale() -> float
@abstract func change_font_size(offset: float) -> void
@abstract func clear_font_size() -> void
