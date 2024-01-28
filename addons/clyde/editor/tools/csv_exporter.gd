@tool
extends PopupPanel

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")
const CsvHelper = preload("./csv.gd")


var _settings = Settings.new()
var _csv_helper = CsvHelper.new()

@onready var file_label: Label = $MarginContainer/VBoxContainer/csv_file_container/file_label
@onready var file_btn: Button = $MarginContainer/VBoxContainer/csv_file_container/HBoxContainer/file_btn
@onready var file_input: LineEdit = $MarginContainer/VBoxContainer/csv_file_container/HBoxContainer/LineEdit
@onready var option_include_meta: CheckBox = $MarginContainer/VBoxContainer/options_container/include_metadata
@onready var option_include_header: CheckBox = $MarginContainer/VBoxContainer/options_container/include_header
@onready var option_locale: LineEdit = $MarginContainer/VBoxContainer/options_container/GridContainer/header_locale
@onready var option_locale_label: Label = $MarginContainer/VBoxContainer/options_container/GridContainer/locale_label
@onready var option_delimiter: LineEdit = $MarginContainer/VBoxContainer/options_container/GridContainer/delimiter
@onready var option_delimiter_label: Label = $MarginContainer/VBoxContainer/options_container/GridContainer/delimiter_label
@onready var options_label: Label = $MarginContainer/VBoxContainer/options_container/options
@onready var export_btn: Button = $MarginContainer/VBoxContainer/buttons/export_btn
@onready var cancel_btn: Button = $MarginContainer/VBoxContainer/buttons/cancel

@onready var warning_container = $MarginContainer/VBoxContainer/csv_file_container/warning
@onready var warning_icon = $MarginContainer/VBoxContainer/csv_file_container/warning/TextureRect
@onready var warning_label = $MarginContainer/VBoxContainer/csv_file_container/warning/Label

@onready var save_message = $MarginContainer/VBoxContainer/HBoxContainer/save_message

var _file_path = ""
var _parsed_document

func _ready():
	_setup_fields()
	_setup_warning()


func _setup_fields():
	file_label.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_FILE)
	file_btn.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_NEW_FILE)
	file_btn.get_parent().tooltip_text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_NEW_FILE_DESC)
	option_include_meta.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_INCLUDE_METADATA)
	option_include_meta.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_INCLUDE_METADATA_DESC)
	option_include_header.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_INCLUDE_HEADER)
	option_include_header.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_INCLUDE_HEADER_DESC)
	option_locale_label.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_HEADER_LOCALE)
	option_locale_label.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_HEADER_LOCALE_DESC)
	option_delimiter_label.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_DELIMITER)
	option_delimiter_label.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_DELIMITER_DESC)
	options_label.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_OPTIONS)
	export_btn.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_EXPORT)
	cancel_btn.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_CANCEL)


func _load_config():
	file_input.text = _get_default_file_path()
	option_include_meta.button_pressed = _settings.get_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_METADATA, false)
	option_include_header.button_pressed = _settings.get_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_HEADER, true)
	option_locale.text = _settings.get_project_config(_settings.CSV_EXPORTER_CFG_HEADER_LOCALE, InterfaceText._loaded_locale)
	option_delimiter.text = _settings.get_project_config(_settings.CSV_EXPORTER_CFG_DELIMITER, ",")


func _setup_warning():
	var warning_color: Color = EditorInterface.get_editor_settings().get_setting("text_editor/theme/highlighting/comment_markers/warning_color")
	warning_color = warning_color.lightened(0.3)
	warning_label.add_theme_color_override("font_color", warning_color)
	warning_label.text = InterfaceText.get_string(InterfaceText.KEY_CSV_FILE_EXISTS_WARNING)
	warning_icon.texture = get_theme_icon("StatusWarning", "EditorIcons")


func _on_export_btn_button_up():
	save_message.get_parent().hide()
	_persist_current_config()
	var result = _csv_helper.create_csv_file(file_input.text, _parsed_document)
	if result:
		_record_csv_path()
		_success_message()
	else:
		_failure_message()


func _persist_current_config():
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_METADATA, option_include_meta.button_pressed)
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_HEADER, option_include_header.button_pressed)
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_HEADER_LOCALE, option_locale.text)
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_DELIMITER, option_delimiter.text)


func _on_line_edit_focus_exited():
	_verify_file()


func _on_file_btn_button_up():
	save_message.get_parent().hide()
	self.hide()
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.set_filters(PackedStringArray(["*.csv"]))
	get_parent().add_child(file_dialog)
	if file_input.text != "":
		file_dialog.current_dir = ProjectSettings.globalize_path(file_input.text.get_base_dir())
		file_dialog.current_file = file_input.text.get_file()
	file_dialog.title = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_NEW_FILE)
	file_dialog.file_selected.connect(_on_csv_file_selected.bind(file_dialog))
	file_dialog.close_requested.connect(_on_file_dialog_closed.bind(file_dialog))
	file_dialog.canceled.connect(_on_file_dialog_closed.bind(file_dialog))
	file_dialog.popup_centered_ratio()


func set_current_file(path: String, parsed_document: Dictionary):
	_file_path = path
	_parsed_document = parsed_document
	_load_config()
	_verify_file()
	save_message.get_parent().hide()


func _get_default_file_path():
	var recorded_paths = _settings.get_project_config(_settings.CSV_EXPORTER_RECORDED_PATHS, {})
	if recorded_paths.has(_file_path):
		return recorded_paths[_file_path]
	else:
		return ProjectSettings.localize_path(_file_path.get_base_dir().path_join("%s.csv" % _file_path.get_file().get_basename()))


func _record_csv_path():
	var recorded_paths = _settings.get_project_config(_settings.CSV_EXPORTER_RECORDED_PATHS, {})
	recorded_paths[_file_path] = file_input.text
	_settings.set_project_config(_settings.CSV_EXPORTER_RECORDED_PATHS, recorded_paths)


func _on_cancel_button_up():
	hide()


func _on_popup_hide():
	pass


func _on_csv_file_selected(path, file_dialog):
	file_input.text = ProjectSettings.localize_path(path)
	file_dialog.queue_free()
	popup_centered()
	_verify_file()


func _on_file_dialog_closed(file_dialog):
	file_dialog.queue_free()
	popup_centered()


func _verify_file():
	if file_input.text == "":
		return
	warning_container.visible = FileAccess.file_exists(file_input.text)


func _success_message():
	save_message.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_SUCCEED)
	var success_color = EditorInterface.get_editor_settings().get_setting("text_editor/theme/highlighting/safe_line_number_color")
	success_color.a = 1
	save_message.add_theme_color_override("font_color", success_color)
	save_message.get_parent().show()


func _failure_message():
	save_message.text = InterfaceText.get_string(InterfaceText.KEY_CSV_EXPORTER_FAIL)
	var error_color = EditorInterface.get_editor_settings().get_setting("text_editor/theme/highlighting/mark_color")
	error_color.a = 1
	save_message.add_theme_color_override("font_color", error_color)
	save_message.get_parent().show()


func _hide_save_message():
	save_message.get_parent().hide()


func _on_header_locale_focus_entered():
	_hide_save_message()


func _on_delimiter_focus_entered():
	_hide_save_message()


func _on_include_metadata_focus_entered():
	_hide_save_message()


func _on_include_header_focus_entered():
	_hide_save_message()
