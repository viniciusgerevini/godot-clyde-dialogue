extends Reference

const Interpreter = preload('./interpreter/Interpreter.gd')
const FileLoader = preload("./file_loader.gd")

class_name ClydeDialogue

# Emits when a variable is changed inside the dialogue.
signal variable_changed(name, value, previous_value)
## Emits when an event is triggered inside the dialogue.
signal event_triggered(name)

# Type for regular dialogue line
const CONTENT_TYPE_LINE = Interpreter.CONTENT_TYPE_LINE

# This type is returned when content has options to choose from
const CONTENT_TYPE_OPTIONS = Interpreter.CONTENT_TYPE_OPTIONS

# This type is returned when the dialogue reached an end
const CONTENT_TYPE_END = Interpreter.CONTENT_TYPE_END

var _file_loader = FileLoader.new()

# Custom folder where the interpreter should look for dialogue files
# in case just the name is provided.
# by default, it loads from ProjectSettings dialogue/source_folder
var dialogue_folder setget _set_folder, _get_folder

var _options = {}
var _interpreter


# Set optional settings for current interpreter. [br]
# Options:
#   include_hidden_options (boolean, default false): Returns conditional options even when check resulted in false.
#
func configure(options):
	_options = options

# Load dialogue file
# file_name: path to the dialogue file.
#            i.e 'my_dialogue', 'res://my_dialogue.clyde', res://my_dialogue.json
# block: block name to run. This allows keeping
#        multiple dialogues in the same file.
func load_dialogue(file_name, block = null):
	var doc_path = _file_loader.get_file_path(file_name)
	var file = _file_loader.load_file_in_path(doc_path)
	
	file.doc_path = doc_path

	_interpreter = Interpreter.new()
	_interpreter.init(file, {
		"id_suffix_lookup_separator": _config_id_suffix_lookup_separator(),
		"include_hidden_options": _options.get("include_hidden_options", false)
	})
	_interpreter.set_file_loader(funcref(self, "_load_file"))
	_interpreter.connect("variable_changed", self, "_trigger_variable_changed")
	_interpreter.connect("event_triggered", self, "_trigger_event_triggered")
	if block:
		_interpreter.select_block(block)


# Start or restart dialogue. Variables are not reset.
func start(block_name = null):
	_interpreter.select_block(block_name)


# Get next dialogue content.
# The content may be a line, options or end of dialogue.
func get_content():
	return _interpreter.get_content()


# Choose one of the available options.
func choose(option_index):
	return _interpreter.choose(option_index)


# Set variable to be used in the dialogue
func set_variable(name, value):
	_interpreter.set_variable(name, value)


# Get current value of a variable inside the dialogue.
# name: variable name
func get_variable(name):
	return _interpreter.get_variable(name)


## Set callback to be used when requesting external variables.
## This callback should return the value for the requested variable, which will
## be used in the dialogue.
## Usage:
## [codeblock]
## func foo(variable_name: String):
##    # do the logic to get the correct value for variable_name
##    return 0
##
## var external_var_fetch_callback = funcref(self, "foo")
##
## dialogue.on_external_variable_fetch(external_var_fetch_callback)
## [/codeblock]
func on_external_variable_fetch(callback: FuncRef) -> void:
	_interpreter.on_external_variable_fetch(callback)


## Set callback to be used when an external variable is updated in the dialogue
## Usage:
## [codeblock]
## func foo(variable_name: String, value: Variant):
##    # do the logic to persist new value for variable
##    persistence.set(variable_name, value)
##
## var external_var_update_callback = funcref(self, "foo")
##
## dialogue.on_external_variable_update(external_var_update_callback)
##
## [/codeblock]
func on_external_variable_update(callback: FuncRef) -> void:
	_interpreter.on_external_variable_update(callback)

# Return all variables and internal variables. Useful for persisting the dialogue's internal
# data, such as options already choosen and random variations states.
func get_data():
	return _interpreter.get_data()


# Load internal data
func load_data(data):
	return _interpreter.load_data(data)


# Clear all internal data
func clear_data():
	return _interpreter.clear_data()


func _trigger_variable_changed(name, value, previous_value):
	emit_signal("variable_changed", name, value, previous_value)


func _trigger_event_triggered(name):
	emit_signal("event_triggered", name)


func _config_id_suffix_lookup_separator():
	var lookup_separator = ProjectSettings.get_setting("dialogue/id_suffix_lookup_separator") if ProjectSettings.has_setting("dialogue/id_suffix_lookup_separator") else null
	return lookup_separator if lookup_separator else "&"


func _set_folder(value):
	_file_loader.dialogue_folder = value

func _get_folder():
		return _file_loader.dialogue_folder


func _load_file(file_path: String):
	var doc_path = _file_loader.get_file_path(file_path)
	var doc = _file_loader.load_file_in_path(doc_path)
	if doc.empty():
		return doc
	doc.doc_path = doc_path
	return doc
