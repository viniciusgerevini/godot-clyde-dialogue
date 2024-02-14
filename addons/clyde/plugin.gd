tool
extends EditorPlugin

const ImportPlugin = preload("import_plugin.gd")

const SETTING_SOURCE_FOLDER := "dialogue/source_folder"
const DEFAULT_SOURCE_FOLDER := "res://dialogues/"

const SETTING_ID_SUFFIX_LOOKUP_SEPARATOR := "dialogue/id_suffix_lookup_separator"
const DEFAULT_ID_SUFFIX_LOOKUP_SEPARATOR := "&"
const HELPERS_ENABLED := "dialogue/enable_helpers"

var _import_plugin
var _helpers_enabled = false

func _enter_tree():
	_import_plugin = ImportPlugin.new()
	add_import_plugin(_import_plugin)
	_setup_project_settings()
	_setup_helpers()
	_listen_to_project_settings_changes()


func disable_plugin():
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

	if not ProjectSettings.has_setting(HELPERS_ENABLED):
		ProjectSettings.set(HELPERS_ENABLED, false)
	ProjectSettings.set_initial_value(HELPERS_ENABLED, false)
	ProjectSettings.add_property_info({
		"name": HELPERS_ENABLED,
		"type": TYPE_BOOL,
	})


	ProjectSettings.save()


func _clear_project_settings():
	ProjectSettings.clear(SETTING_SOURCE_FOLDER)
	ProjectSettings.clear(SETTING_ID_SUFFIX_LOOKUP_SEPARATOR)
	ProjectSettings.save()


func _setup_helpers():
	_helpers_enabled = ProjectSettings.get(HELPERS_ENABLED)
	if _helpers_enabled:
		_register_helper_types()


func _register_helper_types():
	add_autoload_singleton("Dialogue", "res://addons/clyde/helpers/dialogue_manager.gd")
	add_custom_type(
		"ClydeDialogueConfig",
		"Node",
		load("res://addons/clyde/helpers/dialogue_config.gd"),
		load(get_script().resource_path.get_base_dir() + "/assets/clyde.svg")
	)


func _remove_helper_types():
	remove_autoload_singleton("Dialogue")
	remove_custom_type("ClydeDialogueConfig")


func _listen_to_project_settings_changes():
	ProjectSettings.connect("project_settings_changed", self, "_on_project_settings_changed")


func _on_project_settings_changed():
	var helpers = ProjectSettings.get(HELPERS_ENABLED)
	if _helpers_enabled == helpers:
		return
	_helpers_enabled = helpers

	if _helpers_enabled:
		_register_helper_types()
	else:
		_remove_helper_types()
