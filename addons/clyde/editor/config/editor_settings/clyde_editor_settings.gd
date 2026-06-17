@abstract extends RefCounted

signal settings_changed

@abstract func get_setting(key: String) -> Variant
@abstract func set_setting(key: String, value) -> void
@abstract func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant
@abstract func set_project_metadata(section: String, key: String, data: Variant) -> void
