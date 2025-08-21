@tool
extends PanelContainer

signal bubble_clicked(line: int, column: int)
signal option_selected(index)

const DialogueOption = preload("./dialogue_option.tscn")

@onready var _speaker_field = $MarginContainer/VBoxContainer/speaker
@onready var _content_field = $MarginContainer/VBoxContainer/content
@onready var _options_container = $MarginContainer/VBoxContainer/MarginContainer/options
@onready var _line_meta = $MarginContainer/VBoxContainer/line_meta
var _meta

func _ready():
	var current_style = get_theme_stylebox("panel")
	var style = StyleBoxFlat.new()
	var color = current_style.get_bg_color().darkened(0.1)
	style.set_bg_color(color)
	style.set_corner_radius_all(5)
	add_theme_stylebox_override("panel", style)


func set_content(content: Dictionary, should_show_meta = false):
	if content.type == "line":
		_configure_line(content, should_show_meta)
	elif content.type == "options":
		_configure_options(content, should_show_meta)


func _configure_line(content: Dictionary, should_show_meta: bool):
	_content_field.text = content.text
	_set_speaker(content)
	_set_meta(content)
	_set_id_and_tags(content, should_show_meta)


func _configure_options(content: Dictionary, should_show_meta: bool):
	if content.text == null:
		_content_field.hide()
	else:
		_content_field.text = content.text

	_set_speaker(content)
	_set_meta(content)
	_set_id_and_tags(content, should_show_meta)

	_options_container.show()
	for index in range(content.options.size()):
		var option = content.options[index]

		var do = DialogueOption.instantiate()
		do.text = "%s. %s" % [index + 1, option.text]
		_options_container.add_child(do)
		do.pressed.connect(_on_option_selected.bind(index))
		if option.visited:
			do.modulate.a = 0.7


func _set_speaker(content: Dictionary):
	if content.speaker == null:
		_speaker_field.hide()
	else:
		_speaker_field.text = content.speaker


func _set_meta(content: Dictionary):
	if content.has("meta"):
		_meta = content.meta


func _set_id_and_tags(content: Dictionary, should_show_meta: bool):
	if content.id != null:
		_add_id_badge(content.id)
	if content.tags != null and content.tags.size() > 0:
		_add_tags_badges(content.tags)
	if  should_show_meta and _line_meta.get_child_count() > 0:
		_line_meta.show()

func _add_id_badge(id):
	var label = Label.new()
	label.text = "id: %s" % id
	_line_meta.add_child(label)


func _add_tags_badges(tags):
	var l = Label.new()
	l.text = "Tags:"
	_line_meta.add_child(l)
	for tag in tags:
		var label = Label.new()
		label.text = tag
		_line_meta.add_child(label)


func _gui_input(event):
	if _meta == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		bubble_clicked.emit(_meta.line, _meta.column)


func _on_option_selected(index: int):
	set_chosen(index)
	option_selected.emit(index)


func set_chosen(index: int):
	for c in _options_container.get_children():
		c.pressed.disconnect(_on_option_selected.bind(c.get_index()))
		c.focus_mode = Button.FOCUS_NONE
		if c.get_index() == index:
			c.modulate = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
