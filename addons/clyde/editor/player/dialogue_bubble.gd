@tool
extends PanelContainer

signal bubble_clicked(line: int, column: int)

@onready var _speaker_field = $MarginContainer/VBoxContainer/speaker
@onready var _content_field = $MarginContainer/VBoxContainer/content

var _meta

func _ready():
	var current_style = get_theme_stylebox("panel")
	var style = StyleBoxFlat.new()
	var color = current_style.get_bg_color().darkened(0.1)
	style.set_bg_color(color)
	style.set_corner_radius_all(5)
	add_theme_stylebox_override("panel", style)


func set_content(content: Dictionary):
	if content.type == "line":
		_configure_line(content)
	# TODO handle options


func _configure_line(content: Dictionary):
	_content_field.text = content.text
	if content.speaker == null:
		_speaker_field.hide()
	else:
		_speaker_field.text = content.speaker
	if content.has("meta"):
		_meta = content.meta

	# TODO tags
	# TODO ids


func _gui_input(event):
	if _meta == null:
		return
	if event is InputEventMouseButton and not event.is_echo():
		get_viewport().set_input_as_handled()
		bubble_clicked.emit(_meta.line, _meta.column)
