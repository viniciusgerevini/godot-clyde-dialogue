extends MarginContainer

var _dialogue

onready var _line = $PanelContainer/MarginContainer/line
onready var _options = $PanelContainer/MarginContainer/options
onready var _dialogue_ended_message = $PanelContainer/MarginContainer/dialogue_ended

func _ready():
	_dialogue = ClydeDialogue.new()
	_dialogue.load_dialogue('pulp_with_blocks')

	_dialogue.connect("event_triggered", self, '_on_event_triggered')
	_dialogue.connect("variable_changed", self, '_on_variable_changed')


func _get_next_dialogue_line():
	var content = _dialogue.get_content()
	if content.type == 'end':
		_line.hide()
		_options.hide()
		_dialogue_ended_message.show()
		return

	if content.type == 'line':
		_set_up_line(content)
		_line.show()
		_options.hide()
	else:
		_set_up_options(content)
		_options.show()
		_line.hide()


func _set_up_line(content):
	_line.get_node("speaker").text = content.get('speaker') if content.get('speaker') != null else ''
	_line.get_node("text").text = content.text


func _set_up_options(options):
	for c in _options.get_node("items").get_children():
		c.queue_free()

	_options.get_node("name").text = options.get('name') if options.get('name') != null else ''
	_options.get_node("speaker").text = options.get('speaker') if options.get('speaker') != null else ''

	var index = 0
	for option in options.options:
		var btn = Button.new()
		btn.text = option.label
		btn.connect("button_down", self, "_on_option_selected", [index])
		_options.get_node("items").add_child(btn)
		index += 1


func _on_option_selected(index):
	_dialogue.choose(index)
	_get_next_dialogue_line()


func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		_get_next_dialogue_line()


func _on_event_triggered(event_name):
	print("Event received: %s" % event_name)


func _on_variable_changed(variable_name, new_value, previous_value):
	print("variable changed: %s old %s new %s" % [variable_name, previous_value, new_value])


func _on_restart_pressed():
	_dialogue_ended_message.hide()
	_dialogue.start()
	_get_next_dialogue_line()
