extends Reference

const Interpreter = preload('./interpreter/Interpreter.gd')

class_name ClydeDialogue

# Emits when a variable is changed inside the dialogue.
signal variable_changed(name, value, previous_value)
# Emits when an external variable is changed inside the dialogue.
signal external_variable_changed(name, value, previous_value)
## Emits when an event is triggered inside the dialogue.
signal event_triggered(name)

# Type for regular dialogue line
const CONTENT_TYPE_LINE = Interpreter.CONTENT_TYPE_LINE

# This type is returned when content has options to choose from
const CONTENT_TYPE_OPTIONS = Interpreter.CONTENT_TYPE_OPTIONS

# This type is returned when the dialogue reached an end
const CONTENT_TYPE_END = Interpreter.CONTENT_TYPE_END

# Custom folder where the interpreter should look for dialogue files
# in case just the name is provided.
# by default, it loads from ProjectSettings dialogue/source_folder
var dialogue_folder = null

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
	var file = _load_file(_get_file_path(file_name))
	_interpreter = Interpreter.new()
	_interpreter.init(file, {
		"id_suffix_lookup_separator": _config_id_suffix_lookup_separator(),
		"include_hidden_options": _options.get("include_hidden_options", false)
	})
	_interpreter.connect("variable_changed", self, "_trigger_variable_changed")
	_interpreter.connect("external_variable_changed", self, "_trigger_external_variable_changed")
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


# Set external variable to be used in the dialogue.
# External variables can be accessed using the `@` prefix and
# are not included in the save object, so they are not persisted between runs.
func set_external_variable(name: String, value):
	return _interpreter.set_variable(name, value)


# Get current value of an external variable set to the dialogue.[br]
# External variables are not persisted between dialogue runs, but they can
# be modified inside the dialogue.
func get_external_variable(name: String):
	return _interpreter.get_variable(name)


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


func _load_file(path) -> Dictionary:
	if path.get_extension() == 'clyde':
		var container = _load_clyde_file(path)
		return container as Dictionary

	var f := File.new()
	f.open(path, File.READ)
	var result := JSON.parse(f.get_as_text())
	f.close()
	if result.error:
		printerr("Failed to parse file: ", f.get_error())
		return {}

	return result.result as Dictionary


func _load_clyde_file(path):
	var data = load(path)
	return data.content


func _trigger_variable_changed(name, value, previous_value):
	emit_signal("variable_changed", name, value, previous_value)


func _trigger_external_variable_changed(name, value, previous_value):
	emit_signal("external_variable_changed", name, value, previous_value)


func _trigger_event_triggered(name):
	emit_signal("event_triggered", name)


func _get_file_path(file_name):
	var p = file_name
	var extension = file_name.get_extension()

	if (not extension):
		p = "%s.clyde" % file_name

	if p.begins_with('./') or p.begins_with('res://'):
		return p

	return _get_source_folder().plus_file(p)


func _get_source_folder():
	var cfg_folder = ProjectSettings.get_setting("dialogue/source_folder") if ProjectSettings.has_setting("dialogue/source_folder") else null
	var folder = dialogue_folder if dialogue_folder else cfg_folder
	# https://github.com/godotengine/godot/issues/56598
	return folder if folder else "res://dialogues/"


func _config_id_suffix_lookup_separator():
	var lookup_separator = ProjectSettings.get_setting("dialogue/id_suffix_lookup_separator") if ProjectSettings.has_setting("dialogue/id_suffix_lookup_separator") else null
	return lookup_separator if lookup_separator else "&"

