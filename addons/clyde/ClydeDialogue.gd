extends Node

const Interpreter = preload('./interpreter/Interpreter.gd')

class_name ClydeDialogue

signal variable_changed(name, value)
signal event_triggered(name)

var dialogue_folder = 'res://dialogues/'

var _interpreter

func load_dialogue(file_name, _block = null):
	var file = _load_file(_get_file_path(file_name))
	_interpreter = Interpreter.new()
	_interpreter.init(file)
	_interpreter.connect("variable_changed", self, "_trigger_variable_changed")
	_interpreter.connect("event_triggered", self, "_trigger_event_triggered")
	if _block:
		_interpreter.select_block(_block)


func start(block_name = null):
	_interpreter.select_block(block_name)


func get_content():
	return _interpreter.get_content()


func choose(option_index):
	return _interpreter.choose(option_index)


func set_variable(name, value):
	_interpreter.set_variable(name, value)


func get_variable(name):
	return _interpreter.get_variable(name)


func get_data():
	return _interpreter.get_data()


func load_data(data):
	return _interpreter.load_data(data)


func clear_data():
	return _interpreter.clear_data()


func _load_file(path) -> Dictionary:
	var f := File.new()
	f.open(path, File.READ)
	var result := JSON.parse(f.get_as_text())
	f.close()
	if result.error:
		printerr("Failed to parse file: ", f.get_error())
		return {}

	return result.result as Dictionary


func _trigger_variable_changed(name, value):
	emit_signal("variable_changed", name, value)


func _trigger_event_triggered(name):
	emit_signal("event_triggered", name)


func _get_file_path(file_name):
	var p = file_name
	if (not file_name.get_extension()):
		p = "%s.json" % file_name

	if p.begins_with('./') or p.begins_with('res://'):
		return p

	return dialogue_folder.plus_file(p)
