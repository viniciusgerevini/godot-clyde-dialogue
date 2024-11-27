extends MarginContainer

var _dialogue
var _external_persistence = {}

onready var _line = $PanelContainer/MarginContainer/line
onready var _options = $PanelContainer/MarginContainer/options
onready var _dialogue_ended_message = $PanelContainer/MarginContainer/dialogue_ended

func _ready():
	_dialogue = ClydeDialogue.new()
	_dialogue.load_dialogue('pulp_with_blocks')

	_dialogue.connect("event_triggered", self, '_on_event_triggered')
	_dialogue.connect("variable_changed", self, '_on_variable_changed')

	_dialogue.on_external_variable_fetch(funcref(self, "_on_external_variable_fetch"))
	_dialogue.on_external_variable_update(funcref(self, "_on_external_variable_update"))


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


func _on_event_triggered(event_name, parameters):
	print("Event received: %s parameters: %s" % [event_name, parameters])


func _on_variable_changed(variable_name, new_value, previous_value):
	print("variable changed: %s old %s new %s" % [variable_name, previous_value, new_value])


func _on_restart_pressed():
	_dialogue_ended_message.hide()
	_dialogue.start()
	_get_next_dialogue_line()


# this is an example on how to provide access to external variables.
# The dialogue used in this example does not use external variables, but for instance,
# if it tried to access { @health }, this method would be called and return the value from
# _external_persistence["health"]
func _on_external_variable_fetch(variable_name: String):
	return _external_persistence[variable_name]


# This method is called when the dialogue tries to set an external variable. i.e { set @health = 10 }
func _on_external_variable_update(variable_name: String, value):
	_external_persistence[variable_name] = value
