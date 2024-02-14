@tool
extends VBoxContainer

signal parsing_finished(result)
signal content_changed
signal search_requested

const ParseWorker = preload("../parse_worker.gd")

@onready var editor: CodeEdit = $DialogueEditor
@onready var status_bar = $StatusBar

@onready var parse_worker = ParseWorker.new()

var _parsed_document

func _ready():
	parse_worker.processing_finished.connect(_on_parsing_finished)
	parse_worker.processing_failed.connect(_on_parsing_failed)


func _exit_tree():
	parse_worker.stop_worker()


func _on_dialogue_editor_finished_change():
	status_bar.clear_errors()
	status_bar.set_loading()
	parse_worker.parse(editor.text)


func _on_dialogue_editor_caret_changed():
	status_bar.set_caret_position(editor.get_caret_line(), editor.get_caret_column())


func _on_dialogue_editor_text_changed():
	status_bar.set_loading()
	content_changed.emit()


func _on_status_bar_error_hint_clicked(line, column):
	editor.go_to_position(line, column)


func go_to_position(line: int, column: int):
	editor.go_to_position(line, column)


func _on_parsing_finished():
	_parsed_document = parse_worker.get_parse_result()
	status_bar.call_deferred("clear_errors")
	editor.call_deferred("clear_errors")
	editor.call_deferred("set_parsed_document", _parsed_document)
	status_bar.call_deferred("clear_status")
	call_deferred("_notify_parsing_finished", _parsed_document)


func _notify_parsing_finished(parsed_doc):
	parsing_finished.emit(_parsed_document)


func _on_parsing_failed(result):
	status_bar.call_deferred("add_error", result)
	editor.call_deferred("add_error", result)


func get_parsed_document():
	return _parsed_document


func get_content():
	return editor.text


func set_content(content: String):
	if content != editor.text:
		editor.text = content
		_on_dialogue_editor_finished_change()


func set_executing_line(line: int):
	editor.set_executing_line(line)


func clear_executing_lines():
	editor.clear_executing_lines()


func clear_undo_history():
	editor.clear_undo_history()


func _on_dialogue_editor_search_requested():
	search_requested.emit()


func set_search(search_obj, should_go_to_position: bool = false):
	if search_obj == null:
		editor.clear_search()
		return
	editor.set_search(search_obj, should_go_to_position)


func clear_search():
	editor.clear_search()


func search_next(search_obj: Dictionary):
	editor.search_next(search_obj)


func search_previous(search_obj: Dictionary):
	editor.search_previous(search_obj)


func focus():
	editor.grab_focus()


func refresh_config():
	editor.refresh_config()
