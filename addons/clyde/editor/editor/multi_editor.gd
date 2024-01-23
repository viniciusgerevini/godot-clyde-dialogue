@tool
extends MarginContainer

signal editor_switched(key: String)
signal editor_removed(key: String)
signal content_changed
signal parsing_finished(result: Dictionary)

const DialogueEditor = preload("res://addons/clyde/editor/editor/editor.tscn")

var _editors = {}
@onready
var _default_editor = $DefaultEditor
@onready
var _current_editor = _default_editor
var _current_editor_key
var _latest_execution

func switch_editor(key: String):
	if key == "":
		return
	if _editors.has(key):
		_current_editor.hide()
		_current_editor = _editors[key]
		_current_editor_key = key
		_current_editor.show()
		editor_switched.emit(key)
		return

	_editors[key] = _create_editor()
	_initilize_editor(key, _editors[key])
	_current_editor.hide()
	_current_editor = _editors[key]
	_current_editor_key = key
	_current_editor.show()
	editor_switched.emit(key)


func change_editor_key(old_key: String, new_key: String):
	if not _editors.has(old_key):
		return
	_editors[new_key] = _editors[old_key]
	_remove_editor_listeners(old_key, _editors[new_key])
	_editors.erase(old_key)
	_initilize_editor(new_key, _editors[new_key])

	if old_key == _current_editor_key:
		_current_editor_key = new_key


func _create_editor():
	var e = DialogueEditor.instantiate()
	add_child(e)
	return e


func remove_editor(key):
	var e = _editors[key]
	_editors.erase(key)
	if key == _current_editor_key:
		if _editors.is_empty():
			_current_editor = _default_editor
			_current_editor_key = ""
		else:
			for d in _editors:
				_current_editor_key = d
				_current_editor = _editors[d]
				_current_editor.show()
				break
		editor_switched.emit(_current_editor_key)
	e.hide()
	e.queue_free()
	editor_removed.emit(key)


func _initilize_editor(key: String, editor: Node):
	editor.content_changed.connect(_on_editor_content_changed.bind(key))
	editor.parsing_finished.connect(_on_parsing_finished.bind(key))


func _remove_editor_listeners(key: String, editor: Node):
	editor.content_changed.disconnect(_on_editor_content_changed.bind(key))
	editor.parsing_finished.disconnect(_on_parsing_finished.bind(key))


func _on_editor_content_changed(editor_key: String):
	if editor_key != _current_editor_key:
		return
	content_changed.emit()


func _on_parsing_finished(result: Dictionary, editor_key: String):
	if editor_key != _current_editor_key:
		return
	parsing_finished.emit(result)


func get_parsed_document():
	return _current_editor.get_parsed_document()


func get_content(key = null):
	if key == null:
		return _current_editor.get_content()
	return _editors[key].get_content()


func go_to_position(line: int, column: int):
	_current_editor.go_to_position(line, column)


func set_content(content: String):
	_current_editor.set_content(content)


func set_executing_line(key: String, line: int):
	_latest_execution = key
	if _editors.has(key):
		_editors[key].set_executing_line(line)


func clear_executing_line(key: String = ""):
	if key == "" and _latest_execution != null:
		key = _latest_execution
	_latest_execution = null
	if _editors.has(key):
		_editors[key].clear_executing_lines()


func has_editor(key: String):
	return _editors.has(key)


func clear_undo_history():
	_current_editor.clear_undo_history()
