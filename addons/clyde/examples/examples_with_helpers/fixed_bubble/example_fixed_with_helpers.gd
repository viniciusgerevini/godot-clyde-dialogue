extends MarginContainer

@onready var _dialogue_start_button := $Button

var _is_dialogue_running := false

# NOTE This example requires the helpers option to be enabled in Project Settings.

func _ready():
	_setup_dialogue_events()
	_load_buttons()


func _on_button_pressed():
	# TODO move dialogue examples to addon folder
	Dialogue.start_dialogue("res://dialogues/pulp_with_blocks.clyde")


func _setup_dialogue_events():
	Dialogue.dialogue_started.connect(_on_dialogue_started)
	Dialogue.dialogue_ended.connect(_on_dialogue_ended)
	Dialogue.variable_changed.connect(_on_variable_changed)
	Dialogue.external_variable_changed.connect(_on_external_variable_changed)
	Dialogue.event_triggered.connect(_on_event_triggered)
	Dialogue.speaker_changed.connect(_on_speaker_changed)


func _on_dialogue_started(dialogue_name: String, block_name: String):
	print("Dialogue started: %s %s" % [dialogue_name, block_name])
	# In your game, this signal can be used for suspending input and other actions
	# so they don't conflict with the dialogue input.
	_dialogue_start_button.hide()
	_is_dialogue_running = true


func _on_dialogue_ended(dialogue_name: String, block_name: String):
	print("Dialogue ended: %s %s" % [dialogue_name, block_name])
	# This signal can be used to resume the game or input
	await get_tree().create_timer(0.5).timeout
	_dialogue_start_button.show()
	_is_dialogue_running = false


func _on_variable_changed(variable_name: String, value: Variant, old_value: Variant):
	print("Variable changed: %s new: %s old: %s " % [ variable_name, value, old_value ])
	# A variable changed in the event. This is useful for reacting to variable changes.
	# This can be used also as a form of event with payload.


func _on_external_variable_changed(variable_name: String, value: Variant, old_value: Variant):
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
	var config = $HUD/MarginContainer/ClydeDialogueConfig

	$commands/next/Action.text = _input_label(config._next_content_input_action_name)
	$commands/confirm/Action.text = _input_label(config._select_option_input_action_name)
	$commands/select/Action.text = _input_label(config._previous_option_input_action_name)
	$commands/select/Action.text += " / " + _input_label(config._next_option_input_action_name)


func _input_label(actionName: StringName):
	var events = InputMap.action_get_events(actionName)
	var events_text = []
	for e in events:
		if e is InputEventKey:
			events_text.push_back(e.as_text())
	return " / ".join(events_text)
