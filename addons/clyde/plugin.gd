@tool
extends EditorPlugin

const ImportPlugin = preload("import_plugin.gd")

const SETTING_SOURCE_FOLDER := "dialogue/source_folder"
const DEFAULT_SOURCE_FOLDER := "res://dialogues/"

const SETTING_ID_SUFFIX_LOOKUP_SEPARATOR := "dialogue/id_suffix_lookup_separator"
const DEFAULT_ID_SUFFIX_LOOKUP_SEPARATOR := "&"

var _import_plugin

func _enter_tree():
	_import_plugin = ImportPlugin.new()
	add_import_plugin(_import_plugin)
	_setup_project_settings()


func _disable_plugin():
	remove_import_plugin(_import_plugin)
	_import_plugin = null
	_clear_project_settings()


func _setup_project_settings():
	if not ProjectSettings.has_setting(SETTING_SOURCE_FOLDER):
		ProjectSettings.set(SETTING_SOURCE_FOLDER, DEFAULT_SOURCE_FOLDER)
		ProjectSettings.set_initial_value(SETTING_SOURCE_FOLDER, DEFAULT_SOURCE_FOLDER)
		ProjectSettings.add_property_info({
			"name": SETTING_SOURCE_FOLDER,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
		})

	if not ProjectSettings.has_setting(SETTING_ID_SUFFIX_LOOKUP_SEPARATOR):
		ProjectSettings.set(SETTING_ID_SUFFIX_LOOKUP_SEPARATOR, DEFAULT_ID_SUFFIX_LOOKUP_SEPARATOR)
		ProjectSettings.set_initial_value(SETTING_ID_SUFFIX_LOOKUP_SEPARATOR, DEFAULT_ID_SUFFIX_LOOKUP_SEPARATOR)
		ProjectSettings.add_property_info({
			"name": SETTING_ID_SUFFIX_LOOKUP_SEPARATOR,
			"type": TYPE_STRING,
		})

	ProjectSettings.save()


func _clear_project_settings():
	ProjectSettings.clear(SETTING_SOURCE_FOLDER)
	ProjectSettings.clear(SETTING_ID_SUFFIX_LOOKUP_SEPARATOR)
	ProjectSettings.save()
