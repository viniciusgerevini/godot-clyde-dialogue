extends MarginContainer

onready var _dialogue_start_button := $VBoxContainer/Button
onready var _dialogue_selector := $VBoxContainer/OptionButton

var _is_dialogue_running := false

var _dialogue_files = [
	"res://addons/clyde/examples/dialogues/pulp_with_blocks.clyde",
	"res://addons/clyde/examples/dialogues/language_features_demo.clyde",
	"res://addons/clyde/examples/dialogues/simple_lines.clyde",
]

var _current_dialogue = 0

# NOTE This example requires the helpers option to be enabled in Project Settings.
func _ready():
	_setup_dialogue_events()
	_load_buttons()


func _on_button_pressed():
	Dialogue.start_dialogue(_dialogue_files[_current_dialogue])


func _setup_dialogue_events():
	Dialogue.connect("dialogue_started", self, "_on_dialogue_started")
	Dialogue.connect("dialogue_ended", self, "_on_dialogue_ended")
	Dialogue.connect("variable_changed", self, "_on_variable_changed")
	Dialogue.connect("external_variable_changed", self, "_on_external_variable_changed")
	Dialogue.connect("event_triggered", self, "_on_event_triggered")
	Dialogue.connect("speaker_changed", self, "_on_speaker_changed")


func _on_dialogue_started(dialogue_name: String, block_name: String):
	print("Dialogue started: %s %s" % [dialogue_name, block_name])
	# In your game, this signal can be used for suspending input and other actions
	# so they don't conflict with the dialogue input.
	$VBoxContainer.hide()
	_is_dialogue_running = true


func _on_dialogue_ended(dialogue_name: String, block_name: String):
	print("Dialogue ended: %s %s" % [dialogue_name, block_name])
	# This signal can be used to resume the game or input
	yield(get_tree().create_timer(0.5), "timeout")
	$VBoxContainer.show()
	_is_dialogue_running = false


func _on_variable_changed(variable_name: String, value, old_value):
	print("Variable changed: %s new: %s old: %s " % [ variable_name, value, old_value ])
	# A variable changed in the event. This is useful for reacting to variable changes.
	# This can be used also as a form of event with payload.


func _on_external_variable_changed(variable_name: String, value, old_value):
	print("External variable changed: %s new: %s old: %s " % [ variable_name, value, old_value ])
	# External variables are not persisted with the dialogue. This event allows you to listen
	# to any updates to these variables and store them properly


func _on_event_triggered(event_name: String):
	print("Event triggered: %s" % event_name)
	# Listen to events triggered by dialogue.
	# One usage example is to do stuff like screen shake, play sounds or specific animations.


func _on_speaker_changed(speaker: String):
	print("Speaker changed: %s" % speaker)
	# This event is useful for when you want to animate your speaker without hooking it
	# to the dialogue box. One example is making other characters look at the talking speaker


func _input(event):
	if _is_dialogue_running:
		return

	if event is InputEventKey:
		# start dialogue on any event
		_on_button_pressed()


# this is only for this demo to show the input instruction in the screen
func _load_buttons():
	for d in _dialogue_files:
		_dialogue_selector.add_item(d.get_file())

	var config = $HUD/MarginContainer/ClydeDialogueConfig
#
	$commands/next/Action.text = _input_label(config._next_content_input_action_name)
	$commands/confirm/Action.text = _input_label(config._select_option_input_action_name)
	$commands/select/Action.text = _input_label(config._previous_option_input_action_name)
	$commands/select/Action.text += " / " + _input_label(config._next_option_input_action_name)


func _input_label(actionName: String):
	var events = InputMap.get_action_list(actionName)
	var events_text = []
	for e in events:
		if e is InputEventKey:
			events_text.push_back(e.as_text())
	return " / ".join(events_text)


func _on_option_button_item_selected(index):
	_current_dialogue = index
