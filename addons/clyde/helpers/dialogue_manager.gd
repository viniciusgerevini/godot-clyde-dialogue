## This autoload is automatically set by the plugin when "enable helpers" is set in Project Settings.
## It allows you to start, stop and listen to dialogues from anywhere, using the "Dialogue" singleton.
extends Node

const DialogueBubbleFixed = preload("res://addons/clyde/helpers/bubbles/dialogue_bubble_fixed.tscn")

signal dialogue_started(dialogue_path: String, block: String)
signal dialogue_ended(dialogue_path: String, block: String)
signal variable_changed(variable_name: String, value: Variant, old_value: Variant)
signal event_triggered(event_name: String, parameters: Array)
signal speaker_changed(current_speaker: String, previous_speaker: String)

var config
var _dialogue: ClydeDialogue
var _current_path: String = ""
var _current_block: String = ""

var _is_options_mode := false
var _has_dialogue_ended := false

var _current_config = null
var _speaker_data = {}

var _bubbles = {}
var _current_bubble = null
var _current_speaker := ""

var _external_variable_fetch_callback
var _external_variable_update_callback

## Start a dialogue. This will create the dialogue bubble based on the configuration set in
## the dialogue config node.
##
## path: Path to dialogue file. Path might be relative to the default dialogue folder (i.e 'my_dialogue')
## or absolute 'res://my_dialogue.clyde'
##
## block: Start dialogue from this block. Empty string means the default block.
##
## speakers: This is a Dictionary where the key is the speaker id/name (defined in the dialogue file),
## and the value is a dictionary with anything. By default, if the value dictionary has a "variables"
## property, the manager will iterate over it and populate the dialogue with them.
## Example:
## {
##    "npc": { "variables": { "name": "Frodo" }, ... }
## }
## In the example above, name will be used as the speaker display name, and also it will be mapped
## to the dialogue and available to be accessed as `@npc_name`. The whole object will be passed to
## the set_speaker method in the dialogue bubble as is.
##
## NOTE: Variables defined via the speakers dictionary have preference over the external variable fetch callback
## and can't be edited via dialogue.
func start_dialogue(path: String, block: String = "", speakers: Dictionary = {}) -> void:
	load_dialogue(path, block, speakers)
	start()


## Setup dialogue but does not execute it.
## Call start() when ready to start dialogue.
## Useful for when initial setup is required before starting. i.e. dialogue.set_variable(...)
func load_dialogue(path: String, block: String = "", speakers: Dictionary = {}) -> void:
	_current_config = _load_config()
	if _current_config == null:
		return
	_current_path = path
	_current_block = block
	_dialogue = ClydeDialogue.new()
	_dialogue.load_dialogue(path, block)
	_load_data(path, block)
	_load_speakers(speakers)
	_dialogue.variable_changed.connect(_on_variable_changed)
	_dialogue.event_triggered.connect(_on_event_triggered)
	_has_dialogue_ended = false

	_dialogue.on_external_variable_fetch(func (variable_name: String):
		if _is_speaker_variable(variable_name):
			return _get_speaker_variable(variable_name)

		return _current_config._on_external_variable_fetch(variable_name)
	)

	_dialogue.on_external_variable_update(func (variable_name: String, value: Variant):
		_current_config._on_external_variable_update(variable_name, value)
	)


func _is_speaker_variable(variable_name: String) -> bool:
	var parts := variable_name.split("_", true, 1)
	if parts.size() < 2:
		return false
	var prefix = parts[0]
	var var_name = parts[1]

	if not _speaker_data.has(prefix) or not _speaker_data[prefix].has("variables"):
		return false

	if not _speaker_data[prefix].variables.has(var_name):
		return false

	return true


func _get_speaker_variable(variable_name: String) -> Variant:
	var parts := variable_name.split("_", true, 1)
	var prefix = parts[0]
	var var_name = parts[1]

	return _speaker_data[prefix].variables[var_name]


func _load_data(path: String, block: String) -> void:
	var data: Dictionary = config.load_data(path, block)
	if data.is_empty():
		return
	_dialogue.load_data(data)


func _load_speakers(speakers: Dictionary):
	for key in speakers:
		_speaker_data[key] = speakers[key]


## Start pre-loaded dialogue
func start() -> void:
	_dialogue.start(_current_block)
	dialogue_started.emit(_current_path, _current_block)
	_next_content()


## set variable to current running dialogue
func set_variable(var_name: String, value: Variant) -> Variant:
	return _dialogue.set_variable(var_name, value)


## get variable from current running dialogue
func get_variable(var_name: String) -> Variant:
	return _dialogue.get_variable(var_name)


## Set callback to be used when requesting external variables.
## This callback should return the value for the requested variable, which will
## be used in the dialogue.
func on_external_variable_fetch(callback: Callable) -> void:
	_external_variable_fetch_callback = callback


## Set callback to be used when an external variable is updated in the dialogue
func on_external_variable_update(callback: Callable) -> void:
	_external_variable_update_callback = callback


func _load_config():
	if not is_instance_valid(config):
		push_error("No ClydeDialogueConfig node found in scene. Unable to render dialogue")
		return
	return config.get_config()


func _on_variable_changed(variable_name: String, value: Variant, old_value: Variant):
	variable_changed.emit(variable_name, value, old_value)


func _on_event_triggered(event_name: String, parameters: Array):
	event_triggered.emit(event_name, parameters)


func _next_content() -> void:
	if _has_dialogue_ended:
		return

	if is_instance_valid(_current_bubble) and _current_bubble.is_animating():
		_current_bubble.show_text()
		return

	if _is_options_mode:
		return

	var content = _dialogue.get_content()

	if content.type == _dialogue.CONTENT_TYPE_END:
		_end_dialogue()
		return

	_is_options_mode = content.type == _dialogue.CONTENT_TYPE_OPTIONS

	_current_bubble = _get_bubble(content.get("speaker"))
	_current_bubble.set_content(content)

	if _current_speaker != content.get("speaker", ""):
		var previous_speaker = _current_speaker
		var new_speaker = content.get("speaker", "")
		_current_speaker = "" if new_speaker == null else new_speaker
		speaker_changed.emit(_current_speaker, previous_speaker)


func _end_dialogue():
	_has_dialogue_ended = true
	config.persist_data(_current_path, _current_block, _dialogue.get_data())
	dialogue_ended.emit(_current_path, _current_block)
	_clear_manager()


func _clear_manager():
	if is_instance_valid(_current_bubble):
		_current_bubble.hide_bubble()
	for s in _bubbles:
		_bubbles[s].queue_free()
	_bubbles = {}
	_current_bubble = null
	_current_config = null
	_current_speaker = ""


func _get_bubble(speaker: Variant):
	var bubble_name = "default"

	if speaker != null:
		bubble_name = speaker
		if not _bubbles.has(speaker):
			var bubble = _create_bubble()
			_bubbles[speaker]  = bubble

			if _speaker_data.has(speaker):
				bubble.set_speaker(_speaker_data[speaker])

	elif not _bubbles.has("default"):
		_bubbles["default"] = _create_bubble()

	_make_visible(_bubbles[bubble_name])

	return _bubbles[bubble_name]


func _create_bubble():
	var bubble
	if _current_config.bubble != null:
		bubble = _current_config.bubble.instantiate()
	else:
		bubble = DialogueBubbleFixed.instantiate()

	_current_config.bubble_container.add_child(bubble)

	bubble.option_selected.connect(_select_option)

	return bubble


func _make_visible(bubble: Node):
	for b in _bubbles:
		_bubbles[b].hide_bubble()
	bubble.show_bubble()


func _input(event):
	if _current_config == null or _has_dialogue_ended:
		return
	if _is_options_mode:
		if event.is_action_pressed(_current_config.input.select_option):
			_select_option()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(_current_config.input.cancel_selection):
			_cancel_options()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(_current_config.input.next_option):
			_next_option()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(_current_config.input.previous_option):
			_previous_option()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(_current_config.input.next_content):
		_next_content()
		get_viewport().set_input_as_handled()


func _next_option():
	_current_bubble.next_option()


func _previous_option():
	_current_bubble.previous_option()


func _select_option():
	if is_instance_valid(_current_bubble) and _current_bubble.is_animating():
		_current_bubble.show_text()
		return
	_dialogue.choose(_current_bubble.get_selected_option())
	_is_options_mode = false
	_next_content()


func _cancel_options():
	if _current_bubble.is_fallback_option_selected():
		_select_option()
	else:
		_current_bubble.cancel_requested()
