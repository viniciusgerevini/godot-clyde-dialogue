## Interface for the Clyde interpreter.
##
## Clyde is a language for writing game dialogues.
## It supports branching dialogues, translations and interfacing with your game through variables and events.
##
## @tutorial: https://thisisvini.com/clyde
class_name ClydeDialogue extends RefCounted

## The interpreter used to run the dialogue.
const Interpreter = preload('./interpreter/Interpreter.gd')
const FileLoader = preload("./file_loader.gd")

## Emits when a variable is changed inside the dialogue.
signal variable_changed(name: String, value: Variant, previous_value: Variant)
## Emits when an event is triggered inside the dialogue.
signal event_triggered(name: String, parameters: Array)

## Type for regular dialogue line
const CONTENT_TYPE_LINE = Interpreter.CONTENT_TYPE_LINE

## This type is returned when content has options to choose from
const CONTENT_TYPE_OPTIONS = Interpreter.CONTENT_TYPE_OPTIONS

## This type is returned when the dialogue reached an end
const CONTENT_TYPE_END = Interpreter.CONTENT_TYPE_END

var _file_loader = FileLoader.new()

## Custom folder where the interpreter should look for dialogue files in case just the name is provided.
## By default, it loads from ProjectSettings dialogue/source_folder
var dialogue_folder:
	set(value):
		_file_loader.dialogue_folder = value
	get:
		return _file_loader.dialogue_folder

var _options = {}
var _interpreter


## Set optional settings for current interpreter. [br]
## Options:
##   include_hidden_options (boolean, default false): Returns conditional options even when check resulted in false.
##
func configure(options: Dictionary) -> void:
	_options = options


## Load dialogue file.[br]
## file_name: path to the dialogue file. I.e 'my_dialogue', 'res://my_dialogue.clyde', res://my_dialogue.json [br]
## block: block name to run. This allows keeping multiple dialogues in the same file. [br]
func load_dialogue(file_name: String, block: String = "") -> void:
	var doc_path = _file_loader.get_file_path(file_name)
	var file = _file_loader.load_file_in_path(doc_path)

	if file.is_empty():
		return

	file.doc_path = doc_path

	_load_parsed_doc(file, block)


## Load dialogue resource.[br]
## dialogue: ClydeDialogueFile resource.[br]
## block: block name to run. This allows keeping multiple dialogues in the same file. [br]
func load_resource(resource: ClydeDialogueFile, block: String = "") -> void:
	var file = resource.content

	if file == null or file.is_empty():
		return

	file.doc_path = resource.resource_path

	_load_parsed_doc(file, block)


func _load_parsed_doc(doc: Dictionary, block: String = "") -> void:
	_interpreter = Interpreter.new()
	_interpreter.init(doc, {
		"id_suffix_lookup_separator": _config_id_suffix_lookup_separator(),
		"include_hidden_options": _options.get("include_hidden_options", false)
	})
	_interpreter.variable_changed.connect(_trigger_variable_changed)
	_interpreter.event_triggered.connect(_trigger_event_triggered)
	_interpreter.set_file_loader(_load_file)
	if block != "":
		_interpreter.select_block(block)


## Start or restart dialogue. Variables are not reset.
func start(block_name: String = "") -> void:
	_interpreter.select_block(block_name)


## Checks if a block with the given name exists.
func has_block(block_name: String) -> bool:
	return _interpreter.has_block(block_name)


## Get next dialogue content. [br]
## The content may be a line, options or end of dialogue.
func get_content() -> Dictionary:
	return _interpreter.get_content()


## Choose one of the available options.
func choose(option_index: int) -> void:
	_interpreter.choose(option_index)


## Set variable to be used in the dialogue.
func set_variable(name: String, value: Variant) -> Variant:
	return _interpreter.set_variable(name, value)


## Get current value of a variable inside the dialogue. [br]
func get_variable(name: String) -> Variant:
	return _interpreter.get_variable(name)


## Set callback to be used when requesting external variables.
## This callback should return the value for the requested variable, which will
## be used in the dialogue.
## Usage:
## [codeblock]
## dialogue.on_external_variable_fetch(func (variable_name: String):
##    # do the logic to get the correct value for variable_name
##    return 0
## )
## [/codeblock]
func on_external_variable_fetch(callback: Callable) -> void:
	_interpreter.on_external_variable_fetch(callback)


## Set callback to be used when an external variable is updated in the dialogue
## Usage:
## [codeblock]
## dialogue.on_external_variable_update(func (variable_name: String, value: Variant):
##    # do the logic to persist new value for variable
##    persistence.set(variable_name, value)
## )
## [/codeblock]
func on_external_variable_update(callback: Callable) -> void:
	_interpreter.on_external_variable_update(callback)


## Return all variables and internal variables. Useful for persisting the dialogue's internal
## data, such as options already choosen and random variations states.
func get_data() -> Dictionary:
	return _interpreter.get_data()


## Load internal data
func load_data(data) -> void:
	_interpreter.load_data(data)


## Clear all internal data
func clear_data() -> void:
	_interpreter.clear_data()


func _trigger_variable_changed(name: String, value: Variant, previous_value: Variant) -> void:
	variable_changed.emit(name, value, previous_value)


func _trigger_event_triggered(name: String, parameters: Array) -> void:
	event_triggered.emit(name, parameters)


func _config_id_suffix_lookup_separator() -> String:
	var lookup_separator = ProjectSettings.get_setting("dialogue/id_suffix_lookup_separator") if ProjectSettings.has_setting("dialogue/id_suffix_lookup_separator") else null
	return lookup_separator if lookup_separator else "&"


func _load_file(file_path: String):
	var doc_path = _file_loader.get_file_path(file_path)
	var doc = _file_loader.load_file_in_path(doc_path)
	if doc.is_empty():
		return doc
	doc.doc_path = doc_path
	return doc
