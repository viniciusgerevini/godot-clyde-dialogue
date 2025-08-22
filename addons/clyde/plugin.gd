@tool
extends EditorPlugin


const ImportPlugin = preload("import_plugin.gd")
const MainPanel = preload("./editor/main_panel.tscn")
const InterfaceText = preload("./editor/config/interface_text.gd")
const DockableWindow = preload("./editor/windows/dockable_window.gd")

const SETTING_SOURCE_FOLDER := "dialogue/source_folder"
const DEFAULT_SOURCE_FOLDER := "res://dialogues/"

const SETTING_ID_SUFFIX_LOOKUP_SEPARATOR := "dialogue/id_suffix_lookup_separator"
const DEFAULT_ID_SUFFIX_LOOKUP_SEPARATOR := "&"
const MAIN_EDITOR_ENABLED := "dialogue/enable_editor"
const HELPERS_ENABLED := "dialogue/enable_helpers"

var _import_plugin
var _main_panel
var _helpers_enabled = false


var _dockable_main_panel


func _enter_tree():
	_import_plugin = ImportPlugin.new()
	add_import_plugin(_import_plugin)
	_setup_project_settings()
	_setup_main_panel()
	_setup_helpers()
	_listen_to_project_settings_changes()


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

	if not ProjectSettings.has_setting(MAIN_EDITOR_ENABLED):
		ProjectSettings.set(MAIN_EDITOR_ENABLED, true)
	ProjectSettings.set_initial_value(MAIN_EDITOR_ENABLED, true)
	ProjectSettings.add_property_info({
		"name": MAIN_EDITOR_ENABLED,
		"type": TYPE_BOOL,
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
	ProjectSettings.clear(MAIN_EDITOR_ENABLED)
	ProjectSettings.save()


func _exit_tree() -> void:
	if is_instance_valid(_import_plugin):
		remove_import_plugin(_import_plugin)
		_import_plugin = null

	if is_instance_valid(_main_panel):
		_main_panel.queue_free()
		_dockable_main_panel = null


func _setup_main_panel() -> void:
	InterfaceText.plugin_version = get_plugin_version()
	if not ProjectSettings.get_setting(MAIN_EDITOR_ENABLED, true):
		return

	_main_panel = MainPanel.instantiate()
	_main_panel.editor_plugin = self

	_dockable_main_panel = DockableWindow.new(
		get_editor_interface().get_editor_main_screen(),
		get_editor_interface().get_base_control(),
		_main_panel
	)

	_make_visible(false)


func _has_main_screen() -> bool:
	return ProjectSettings.get_setting(MAIN_EDITOR_ENABLED, true)


func _make_visible(is_visible: bool) -> void:
	if is_instance_valid(_main_panel):
		if _dockable_main_panel.is_docked:
			_main_panel.visible = is_visible


func _get_plugin_name() -> String:
	return "Clyde"


func _get_plugin_icon() -> Texture2D:
	return load(get_script().resource_path.get_base_dir() + "/editor/assets/clyde.svg")


func _build() -> bool:
	if is_instance_valid(_main_panel):
		_main_panel.prepare_for_project_run()
	return true


func _handles(object) -> bool:
	if not is_instance_valid(_main_panel):
		return false
	return object is ClydeDialogueFile


func _edit(object):
	if object == null:
		return
	_main_panel.load_file(object.resource_path)


func _setup_helpers():
	_helpers_enabled = ProjectSettings.get_setting(HELPERS_ENABLED, false)
	if _helpers_enabled:
		_register_helper_types()


func _register_helper_types():
	add_autoload_singleton("Dialogue", "res://addons/clyde/helpers/dialogue_manager.gd")
	add_custom_type(
		"ClydeDialogueConfig",
		"Node",
		load("res://addons/clyde/helpers/dialogue_config.gd"),
		_get_plugin_icon()
	)


func _remove_helper_types():
	remove_autoload_singleton("Dialogue")
	remove_custom_type("ClydeDialogueConfig")


func _listen_to_project_settings_changes():
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)


func _on_project_settings_changed():
	var helpers = ProjectSettings.get_setting(HELPERS_ENABLED, false)
	if _helpers_enabled == helpers:
		return
	_helpers_enabled = helpers

	if _helpers_enabled:
		_register_helper_types()
	else:
		_remove_helper_types()
