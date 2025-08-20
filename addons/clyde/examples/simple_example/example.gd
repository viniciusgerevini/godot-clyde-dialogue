extends MarginContainer

# This is a simple example using the ClydeDialogue class.
# No helpers required.

@onready var _line_container = $Panel/MarginContainer/line
@onready var _options_container = $Panel/MarginContainer/options
@onready var _end_container = $Panel/MarginContainer/dialogue_ended

var _dialogue

var _external_persistence = {}

func _ready():
	_dialogue = ClydeDialogue.new()
	_dialogue.load_dialogue('pulp_with_blocks')

	_dialogue.event_triggered.connect(_on_event_triggered)
	_dialogue.variable_changed.connect(_on_variable_changed)

	_dialogue.on_external_variable_fetch(_on_external_variable_fetch)
	_dialogue.on_external_variable_update(_on_external_variable_update)


func _get_next_dialogue_line():
	var content = _dialogue.get_content()
	if content.type == "end":
		_line_container.hide()
		_options_container.hide()
		_end_container.show()
		return

	if content.type == 'line':
		_set_up_line(content)
		_line_container.show()
		_options_container.hide()
	else:
		_set_up_options(content)
		_options_container.show()
		_line_container.hide()


func _set_up_line(content):
	_line_container.get_node("speaker").text = content.get('speaker') if content.get('speaker') != null else ''
	_line_container.get_node("text").text = content.text


func _set_up_options(options):
	for c in _options_container.get_node("items").get_children():
		c.queue_free()

	_options_container.get_node("name").text = options.get('text') if options.get('text') != null else ''
	_options_container.get_node("speaker").text = options.get('speaker') if options.get('speaker') != null else ''
	_options_container.get_node("speaker").visible = _options_container.get_node("speaker").text != ""

	var index = 0
	for option in options.options:
		var btn = Button.new()
		btn.text = option.text
		btn.connect("button_down",Callable(self,"_on_option_selected").bind(index))
		_options_container.get_node("items").add_child(btn)
		index += 1


func _on_option_selected(index):
	_dialogue.choose(index)
	_get_next_dialogue_line()


func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		_get_next_dialogue_line()


func _on_event_triggered(event_name, parameters):
	print("Event received: %s params: %s " % [event_name, parameters])


func _on_variable_changed(variable_name, new_value, previous_value):
	print("variable changed: %s old %s new %s" % [variable_name, previous_value, new_value])


func _on_restart_pressed():
	_end_container.hide()
	_dialogue.start()
	_get_next_dialogue_line()


# this is an example on how to provide access to external variables.
# The dialogue used in this example does not use external variables, but for instance,
# if it tried to access { @health }, this method would be called and return the value from
# _external_persistence["health"]
func _on_external_variable_fetch(variable_name: String):
	return _external_persistence[variable_name]


# This method is called when the dialogue tries to set an external variable. i.e { set @health = 10 }
func _on_external_variable_update(variable_name: String, value: Variant):
	_external_persistence[variable_name] = value
