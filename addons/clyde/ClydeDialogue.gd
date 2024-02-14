extends RefCounted


class_name ClydeDialogue
## Interface for the Clyde interpreter.
##
## Clyde is a language for writing game dialogues.
## It supports branching dialogues, translations and interfacing with your game through variables and events.
##
## @tutorial: https://github.com/viniciusgerevini/godot-clyde-dialogue/blob/godot_4/USAGE.md


## The interpreter used to run the dialogue.
const Interpreter = preload('./interpreter/Interpreter.gd')


## Emits when a variable is changed inside the dialogue.
signal variable_changed(name, value, previous_value)
## Emits when an event is triggered inside the dialogue.
signal event_triggered(name)


## Custom folder where the interpreter should look for dialogue files in case just the name is provided.
## By default, it loads from ProjectSettings dialogue/source_folder
var dialogue_folder = null

var _options = {}
var _interpreter


## Set optional settings for current interpreter. [br]
## Options:
##   include_hidden_options (boolean, default false): Returns conditional options even when check resulted in false.
##
func configure(options):
	_options = options


## Load dialogue file. [br]
## file_name: path to the dialogue file. I.e 'my_dialogue', 'res://my_dialogue.clyde', res://my_dialogue.json [br]
## block: block name to run. This allows keeping multiple dialogues in the same file. [br]
func load_dialogue(file_name, block = null):
	var file = _load_file(_get_file_path(file_name))

	if file.is_empty():
		return

	_interpreter = Interpreter.new()
	_interpreter.init(file, {
		"id_suffix_lookup_separator": _config_id_suffix_lookup_separator(),
		"include_hidden_options": _options.get("include_hidden_options", false)
	})
	_interpreter.connect("variable_changed",Callable(self,"_trigger_variable_changed"))
	_interpreter.connect("event_triggered",Callable(self,"_trigger_event_triggered"))
	if block:
		_interpreter.select_block(block)


## Start or restart dialogue. Variables are not reset.
func start(block_name = null):
	_interpreter.select_block(block_name)


## Checks if a block with the given name exists.
func has_block(block_name):
	return _interpreter.has_block(block_name)


## Get next dialogue content. [br]
## The content may be a line, options or end of dialogue.
func get_content():
	return _interpreter.get_content()


## Choose one of the available options.
func choose(option_index):
	return _interpreter.choose(option_index)


## Set variable to be used in the dialogue.
func set_variable(name, value):
	_interpreter.set_variable(name, value)


## Get current value of a variable inside the dialogue. [br]
## name: variable name
func get_variable(name):
	return _interpreter.get_variable(name)


## Return all variables and internal variables. Useful for persisting the dialogue's internal
## data, such as options already choosen and random variations states.
func get_data():
	return _interpreter.get_data()


## Load internal data
func load_data(data):
	return _interpreter.load_data(data)


## Clear all internal data
func clear_data():
	return _interpreter.clear_data()


func _load_file(path) -> Dictionary:
	if path.get_extension() == 'clyde':
		var container = _load_clyde_file(path)
		return container as Dictionary

	var f := FileAccess.open(path, FileAccess.READ)
	var json_file = JSON.new()
	var parse_error = json_file.parse(f.get_as_text())
	f.close()
	if parse_error != OK or typeof(json_file.data) != TYPE_DICTIONARY:
		printerr("Failed to parse file: ", json_file.get_error_message())
		return {}

	return json_file.data


func _load_clyde_file(path) -> Dictionary:
	var data = load(path).__data__.get_string_from_utf8()
	var json_file = JSON.new()
	var parse_error = json_file.parse(data)

	if parse_error != OK or typeof(json_file.data) != TYPE_DICTIONARY:
		var format = [json_file.get_error_line(), json_file.get_error_message()]
		var error_string = "%d: %s" % format
		printerr("Could not parse json", error_string)
		return {}

	return json_file.data


func _trigger_variable_changed(name, value, previous_value):
	emit_signal("variable_changed", name, value, previous_value)


func _trigger_event_triggered(name):
	emit_signal("event_triggered", name)


func _get_file_path(file_name):
	var p = file_name
	var extension = file_name.get_extension()

	if (extension == ""):
		p = "%s.clyde" % file_name

	if p.begins_with('./') or p.begins_with('res://'):
		return p

	return _get_source_folder().path_join(p)


func _get_source_folder():
	var cfg_folder = ProjectSettings.get_setting("dialogue/source_folder") if ProjectSettings.has_setting("dialogue/source_folder") else null
	var folder = dialogue_folder if dialogue_folder else cfg_folder
	# https://github.com/godotengine/godot/issues/56598
	return folder if folder else "res://dialogues/"


func _config_id_suffix_lookup_separator():
	var lookup_separator = ProjectSettings.get_setting("dialogue/id_suffix_lookup_separator") if ProjectSettings.has_setting("dialogue/id_suffix_lookup_separator") else null
	return lookup_separator if lookup_separator else "&"

