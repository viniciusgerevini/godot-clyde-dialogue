@tool extends MarginContainer

signal dock_button_pressed

const ClydeEditorSettings = preload("./config/settings.gd")
const ClydeInEditorSettings = preload("./config/editor_settings/in_editor_settings.gd")
const PluginRoot = preload("./app_root/plugin_root.gd")

var editor_plugin: EditorPlugin

@onready var _main_panel = $MainPanel

# TODO EditorInterface
# TODO EditorFileDialogue

func _ready() -> void:
	_main_panel.setup(
		PluginRoot.new(editor_plugin),
		ClydeEditorSettings.new(ClydeInEditorSettings.new())
	)


func prepare_for_project_run() -> void:
	_main_panel.prepare_for_project_run()


func load_file(path: String) -> void:
	_main_panel.load_file(path)


func _on_main_panel_dock_button_pressed() -> void:
	dock_button_pressed.emit()
