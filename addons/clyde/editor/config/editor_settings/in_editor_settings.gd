extends "./clyde_editor_settings.gd"

var _editor_settings: EditorSettings

func _init():
	_editor_settings = EditorInterface.get_editor_settings()
	_editor_settings.settings_changed.connect(_on_settings_changed)

func get_setting(key: String) -> Variant:
	return _editor_settings.get_setting(key)

func set_setting(key: String, value) -> void:
	_editor_settings.set_setting(key, value)


func get_project_metadata(section: String, key: String, default: Variant = null) -> Variant:
	return _editor_settings.get_project_metadata(section, key, default)


func set_project_metadata(section: String, key: String, data: Variant) -> void:
	_editor_settings.set_project_metadata(section, key, data)


func _on_settings_changed():
	settings_changed.emit()


func get_interface_scale() -> float:
	return EditorInterface.get_editor_scale()
