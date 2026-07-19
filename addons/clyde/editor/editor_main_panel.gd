@tool extends MarginContainer

signal dock_button_pressed

const ClydeEditorSettings = preload("./config/settings.gd")
const PluginRoot = preload("./app_root/plugin_root.gd")
const AboutWindow = preload("./help/about.tscn")
const InterfaceText = preload("res://addons/clyde/editor/config/interface_text.gd")

var settings: ClydeEditorSettings
var editor_plugin: EditorPlugin

@onready var _main_panel = $MainPanel


func _ready() -> void:
	_main_panel.setup(
		PluginRoot.new(editor_plugin),
		settings
	)


func prepare_for_project_run() -> void:
	_main_panel.prepare_for_project_run()


func load_file(path: String) -> void:
	_main_panel.load_file(path)


func _on_main_panel_dock_button_pressed() -> void:
	dock_button_pressed.emit()


func _on_main_panel_file_system_scan_requested() -> void:
	EditorInterface.get_resource_filesystem().scan()


func _on_main_panel_show_in_file_system_triggered(file_path: String) -> void:
	EditorInterface.get_file_system_dock().navigate_to_path(ProjectSettings.localize_path(file_path))


func _on_main_panel_about_triggered() -> void:
	var about: Window = AboutWindow.instantiate()
	add_child(about)
	about.set_license_notice(_get_license_content())
	about.setup(
		InterfaceText.get_string(InterfaceText.KEY_ABOUT_WINDOW_TITLE),
		InterfaceText.get_string(InterfaceText.KEY_ABOUT_TITLE),
		InterfaceText.get_string(InterfaceText.KEY_ABOUT_DESCRIPTION),
		InterfaceText.plugin_version,
	)
	about.popup_centered()


func _get_license_content() -> String:
	var file: FileAccess = FileAccess.open("res://addons/clyde/LICENSE", FileAccess.READ)
	return file.get_as_text()
