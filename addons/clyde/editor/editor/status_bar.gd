@tool
extends HBoxContainer

signal error_hint_clicked(line, column)

@onready
var error_hint = $ErrorContainer/ErrorHint
var _errors = []

@onready
var _loading_icon = $CenterContainer/loading_container/loading
@onready
var _ok_icon = $CenterContainer/loading_container/ok
@onready
var _warning_icon = $CenterContainer/loading_container/warning

func _ready():
	var error_color = EditorInterface.get_editor_settings().get_setting("text_editor/theme/highlighting/mark_color")
	error_color.a = 1
	error_hint.add_theme_color_override("font_color", error_color)
	_configure_loading_icon()


func set_caret_position(line: int, column: int):
	$CaretPosition.text = "%3d   : %3d" % [line, column]


func add_error(error: Dictionary):
	_errors.push_back(error)
	if _errors.size() > 1:
		return
	var description = ""
	if error.reason == "unexpected_token":
		description = "Error at (%s, %s): Unexpected token \"%s\". Expected: %s" % [
			error.line + 1,
			error.column + 1,
			error.friendly_token_name,
			error.expected_hints,
		]

	error_hint.show()
	error_hint.text = description
	error_hint.tooltip_text = description
	_ok_icon.hide()
	_warning_icon.show()
	_loading_icon.hide()


func clear_errors():
	_errors = []
	error_hint.hide()
	error_hint.text = ""
	error_hint.tooltip_text = ""
	_ok_icon.hide()
	_warning_icon.hide()


func get_errors():
	return _errors


func _on_error_hint_gui_input(event):
	if event is InputEventMouseButton and _errors.size() > 0:
		error_hint_clicked.emit(_errors[0].line, _errors[0].column)


func set_loading():
	_loading_icon.show()
	_ok_icon.hide()
	_warning_icon.hide()


func clear_status():
	_loading_icon.hide()
	_ok_icon.show()
	_warning_icon.hide()


func _configure_loading_icon():
	_loading_icon.sprite_frames.clear("default")
	for i in range(8):
		var icon = get_theme_icon("Progress%s" % (i + 1), "EditorIcons")
		_loading_icon.sprite_frames.add_frame("default", icon)
	_loading_icon.play("default")

	_ok_icon.texture = get_theme_icon("StatusSuccess", "EditorIcons")
	_warning_icon.texture = get_theme_icon("StatusError", "EditorIcons")
