@tool
extends EditorPlugin

const ImportPlugin = preload("import_plugin.gd")
const ScriptEditorContextMenuPlugin = preload("./editor/context_menus/script_editor_context_menu.gd")
const FileSystemContextMenuPlugin = preload("./editor/context_menus/file_system_context_menu.gd")
const InterfaceText = preload("./editor/config/interface_text.gd")
const ClydeEditorSettings = preload("./editor/config/settings.gd")
const ClydeInEditorSettings = preload("./editor/config/editor_settings/in_editor_settings.gd")
const BuiltInEditorFeatures = preload("./editor/built_in/editor_features.gd")
const PlayerDock = preload("./editor/docks/player_dock.gd")
const ToolMenu = preload("./editor/tool_menu/setup.gd")
const CsvExporterDialogue = preload("./editor/tools/csv_exporter.tscn")
const AboutWindow = preload("./editor/help/about.tscn")

const SETTING_SOURCE_FOLDER := "dialogue/source_folder"
const DEFAULT_SOURCE_FOLDER := "res://dialogues/"

const SETTING_ID_SUFFIX_LOOKUP_SEPARATOR := "dialogue/id_suffix_lookup_separator"
const DEFAULT_ID_SUFFIX_LOOKUP_SEPARATOR := "&"
const HELPERS_ENABLED := "dialogue/enable_helpers"

var _import_plugin
var _player_dock: PlayerDock
var _script_editor_context_menu_plugin: ScriptEditorContextMenuPlugin
var _file_system_context_menu_plugin: FileSystemContextMenuPlugin
var _tool_menu: ToolMenu = ToolMenu.new()
var _helpers_enabled = false

var _editor_settings: ClydeEditorSettings
var _editor_features: BuiltInEditorFeatures

func _enter_tree():
	_editor_settings = ClydeEditorSettings.new(ClydeInEditorSettings.new())
	_import_plugin = ImportPlugin.new()
	add_import_plugin(_import_plugin)
	_setup_project_settings()
	_setup_main_panel()
	_setup_helpers()
	_listen_to_project_settings_changes()
	_enhance_builtin_editor()
	_register_player_dock()
	_register_context_menu_plugin()
	_register_tool_menu()


func _disable_plugin():
	remove_import_plugin(_import_plugin)
	_import_plugin = null
	_clear_project_settings()
	_clear_builtin_editor()
	_unregister_player_dock()
	_unregister_context_menu_plugin()
	_unregister_tool_menu()


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

	_register_clyde_file_in_editor_settings()


func _clear_project_settings():
	ProjectSettings.clear(SETTING_SOURCE_FOLDER)
	ProjectSettings.clear(SETTING_ID_SUFFIX_LOOKUP_SEPARATOR)
	ProjectSettings.save()


func _exit_tree() -> void:
	if is_instance_valid(_import_plugin):
		remove_import_plugin(_import_plugin)
		_import_plugin = null


func _setup_main_panel() -> void:
	InterfaceText.load_strings_for_current_locale()
	InterfaceText.plugin_version = get_plugin_version()


func _get_plugin_name() -> String:
	return "Clyde"


func _get_plugin_icon() -> Texture2D:
	return load(get_script().resource_path.get_base_dir() + "/editor/assets/clyde.svg")


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


func _enhance_builtin_editor() -> void:
	_editor_features = BuiltInEditorFeatures.new(EditorInterface.get_script_editor(), _editor_settings)


func _clear_builtin_editor() -> void:
	_editor_features.unregister()
	_editor_features = null


func _register_player_dock() -> void:
	_player_dock = PlayerDock.new()
	_player_dock.register_dock(self, _editor_settings, _editor_features)


func _unregister_player_dock() -> void:
	if _player_dock:
		_player_dock.unregister_dock(self)
		_player_dock = null


func _register_context_menu_plugin() -> void:
	_script_editor_context_menu_plugin = ScriptEditorContextMenuPlugin.new()
	_file_system_context_menu_plugin = FileSystemContextMenuPlugin.new()

	_script_editor_context_menu_plugin.player_requested.connect(_on_player_requested)
	_file_system_context_menu_plugin.player_requested.connect(_on_player_requested)

	_script_editor_context_menu_plugin.csv_exporter_requested.connect(_on_csv_exporter_requested)
	_file_system_context_menu_plugin.csv_exporter_requested.connect(_on_csv_exporter_requested)

	_script_editor_context_menu_plugin.line_id_generation_requested.connect(_on_line_id_generation_requested)

	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _file_system_context_menu_plugin)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _script_editor_context_menu_plugin)


func _unregister_context_menu_plugin() -> void:
	remove_context_menu_plugin(_script_editor_context_menu_plugin)
	remove_context_menu_plugin(_file_system_context_menu_plugin)


func _on_player_requested(dialogue_path: String) -> void:
	_player_dock.open_dock(dialogue_path)


func _on_line_id_generation_requested(dialogue_path: String) -> void:
	_editor_features.generate_line_ids(dialogue_path)


func _register_tool_menu() -> void:
	_tool_menu.setup(self)
	_tool_menu.player_requested.connect(_on_player_requested.bind(""))
	_tool_menu.csv_exporter_requested.connect(_on_csv_exporter_requested.bind(""))
	_tool_menu.about_requested.connect(_on_about_requested)


func _unregister_tool_menu() -> void:
	_tool_menu.remove(self)
	_tool_menu.player_requested.disconnect(_on_player_requested.bind(""))
	_tool_menu.csv_exporter_requested.connect(_on_csv_exporter_requested.bind(""))
	_tool_menu.about_requested.connect(_on_about_requested)


func _on_csv_exporter_requested(dialogue_file: String) -> void:
	var exporter = CsvExporterDialogue.instantiate()
	self.add_child(exporter)
	exporter.setup(_editor_settings)
	if dialogue_file != "":
		exporter.set_current_file(dialogue_file)
	exporter.popup_centered()


func _on_about_requested() -> void:
	var about: Window = AboutWindow.instantiate()
	self.add_child(about)
	about.setup(_editor_settings)
	about.popup_centered()


func _register_clyde_file_in_editor_settings() -> void:
	var editor_settings: EditorSettings = self.get_editor_interface().get_editor_settings()
	var textfiles: String = editor_settings.get_setting("docks/filesystem/textfile_extensions")
	if not textfiles.contains("clyde"):
		editor_settings.set_setting("docks/filesystem/textfile_extensions", textfiles + ",clyde")
