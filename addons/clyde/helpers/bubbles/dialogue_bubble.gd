extends MarginContainer

signal option_selected

const DialogueOption = preload("./dialogue_option.tscn")

const DIALOGUE_TEXT_TICK_WAIT = 0.03

var _time_since_last_tick = 0

@onready var _speaker_field: Label = $panel/HBoxContainer/VBoxContainer/speaker
@onready var _text_field: RichTextLabel = $panel/HBoxContainer/VBoxContainer/text
@onready var _options_container: VBoxContainer = $panel/HBoxContainer/VBoxContainer/options

var _fallback_option
var _selected_option_index = 0
var _waiting_options := false

var _input_config = {}

# These are patterns that will replace the text content and apply BBCODE tags
var _formatting = [
	# _text_ makes it yellow
	{
		"pattern": RegEx.create_from_string("\\_([^_]+)\\_"),
		"sub": "[color=#e0a443]$1[/color]"
	},
	# *text* makes it red
	{
		"pattern": RegEx.create_from_string("\\*([^\\*]+)\\*"),
		"sub": "[color=#cf5555]$1[/color]"
	},
	# |text| makes it green
	{
		"pattern": RegEx.create_from_string("\\|([^\\|]+)\\|"),
		"sub": "[color=#56bf85]$1[/color]"
	},
	# ~text~ makes it wave
	{
		"pattern": RegEx.create_from_string("\\~([^\\~]+)\\~"),
		"sub": "[wave amp=20 freq=10]$1[/wave]"
	},
	# ^text^ makes it shake
	{
		"pattern": RegEx.create_from_string("\\^([^\\^]+)\\^"),
		"sub": "[shake rate=20 level=5]$1[/shake]"
	},
]


func _process(delta):
	if not self.visible:
		return

	_time_since_last_tick += delta
	if _time_since_last_tick >= DIALOGUE_TEXT_TICK_WAIT:
		_on_dialogue_tick()
		_time_since_last_tick = 0


func show_text():
	_text_field.visible_characters = _text_field.get_total_character_count()


func is_animating():
	return _waiting_options or _text_field.visible_characters < _text_field.get_total_character_count()


func hide_bubble():
	self.hide()


func show_bubble():
	self.show()


func set_content(content: Dictionary):
	if _speaker_field.text == "" and content.speaker != null:
		_speaker_field.text = content.speaker
		_speaker_field.show()

	if content.type == 'options':
		_setup_options(content)
		return

	_text_field.visible_characters = 0
	_options_container.hide()
	_text_field.text = _format_text(content.text)
	_text_field.show()


func _format_text(text):
	var t = text
	for s in _formatting:
		t = s.pattern.sub(t, s.sub, true)
	return t


func set_speaker(content: Dictionary):
	if content.get("variables", {}).has("name"):
		_speaker_field.text = content.variables.name
		_speaker_field.show()


func set_input_config(input_config: Dictionary):
	_input_config = input_config


func _on_dialogue_tick():
	if _text_field.visible_characters < _text_field.get_total_character_count():
		_text_field.visible_characters += 1
	elif _options_container.visible and _options_container.modulate.a == 0:
		_options_container.modulate.a = 1
		_options_container.get_child(0).button_pressed = true

		# this is a small workaround to prevent accidental option selection
		# when both next content and option selection use the same action key.
		# There are other ways to do that, but I decided to keep it simple and
		# do it this way.
		_waiting_options = true
		await get_tree().create_timer(0.5).timeout
		_waiting_options = false


func _setup_options(content: Dictionary):
	var button_group = ButtonGroup.new()
	_selected_option_index = 0
	# cleanup previous options
	for c in _options_container.get_children():
		c.queue_free()

	_fallback_option = null
	for option in content.options:
		var i: Button = DialogueOption.instantiate()
		i.text = option.text
		i.button_group = button_group
		i.pressed.connect(_on_option_pressed.bind(i))
		_options_container.add_child(i)
		if option.tags != null:
			if option.tags.has("fallback"):
				_fallback_option  = i

	var content_name = content.get("text")
	if content_name == null or content_name.strip_edges().is_empty():
		_text_field.hide()
	else:
		_text_field.visible_characters = 0
		_text_field.text = _format_text(content_name)
		_text_field.show()
		_options_container.modulate.a = 0

	_options_container.show()
	_options_container.get_child(0).button_pressed = true


func next_option():
	_selected_option_index += 1
	if _selected_option_index >= _options_container.get_child_count():
		_selected_option_index = 0
	_options_container.get_child(_selected_option_index).button_pressed = true


func previous_option():
	_selected_option_index -= 1
	if _selected_option_index < 0:
		_selected_option_index = _options_container.get_child_count() - 1
	_options_container.get_child(_selected_option_index).button_pressed = true


func cancel_requested():
	if _fallback_option != null:
		_fallback_option.button_pressed
		_selected_option_index = _fallback_option.get_index()


func is_fallback_option_selected() -> bool:
	return _fallback_option != null and _fallback_option.button_pressed


func _on_option_pressed(option_node: Node):
	_selected_option_index = option_node.get_index()
	option_selected.emit()


func get_selected_option():
	return _selected_option_index
