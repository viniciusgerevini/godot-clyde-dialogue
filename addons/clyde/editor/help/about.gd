@tool
extends Window

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")

@onready var _title: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/title

# main screen
@onready var _description: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/description
@onready var _version: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/version
@onready var _main_page: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page
@onready var _main_license_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/license
@onready var _main_report_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/report
@onready var _main_online_docs_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/online_docs


# license screen
@onready var _license_page: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/license_page
@onready var _license: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/license_page/license
@onready var _license_back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/license_page/back

var _settings: Settings

func setup(settings: Settings) -> void:
	_settings = settings
	_setup_strings()
	_setup_background(settings)


func _on_close_requested() -> void:
	queue_free()


func _on_description_meta_clicked(meta: Variant) -> void:
	if meta == "LICENSE":
		_on_license_button_down()
		return
	OS.shell_open(str(meta))


func _setup_strings() -> void:
	self.title = InterfaceText.get_string(InterfaceText.KEY_ABOUT_WINDOW_TITLE)
	_title.text = InterfaceText.get_string(InterfaceText.KEY_ABOUT_TITLE)
	_description.text = InterfaceText.get_string(InterfaceText.KEY_ABOUT_DESCRIPTION)
	_version.text = "v%s" % InterfaceText.plugin_version
	_license.text = _get_license_content()

	_main_report_button.text = InterfaceText.get_string(InterfaceText.KEY_HELP_REPORT_ISSUE)
	_main_report_button.icon = _settings.get_theme_icon("external_link")

	_main_online_docs_button.text = InterfaceText.get_string(InterfaceText.KEY_HELP_ONLINE_DOCS)
	_main_online_docs_button.icon = _settings.get_theme_icon("external_link")

	_main_license_button.text = InterfaceText.get_string(InterfaceText.KEY_VIEW_LICENSE)
	_main_license_button.icon = _settings.get_theme_icon("help_license")

	_license_back_button.text = InterfaceText.get_string(InterfaceText.KEY_BACK)


func _setup_background(settings: Settings) -> void:
	var base_color: Color = settings.get_theme_base_color()
	var panel = StyleBoxFlat.new()
	panel.bg_color = base_color
	$PanelContainer.add_theme_stylebox_override("panel", panel)


func _on_back_button_down() -> void:
	_license_page.hide()
	_main_page.show()


func _on_license_button_down() -> void:
	_main_page.hide()
	_license_page.show()


func _get_license_content() -> String:
	var file: FileAccess = FileAccess.open("res://addons/clyde/LICENSE", FileAccess.READ)
	return file.get_as_text()


func _on_main_report_button_down() -> void:
	OS.shell_open(_settings.REPORT_ISSUE_URL)


func _on_main_online_docs_button_down() -> void:
	OS.shell_open(_settings.ONLINE_DOCS_URL)
