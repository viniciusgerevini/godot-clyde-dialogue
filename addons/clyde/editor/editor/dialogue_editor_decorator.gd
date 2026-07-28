@tool
extends RefCounted

signal parsing_finished
signal parsing_failed(result: Dictionary)

const ClydeEditorSettings = preload("../config/settings.gd")
const ParseWorker = preload("../parse_worker.gd")
const Debouncer = preload("../util/debouncer.gd")
const AutoComplete = preload("./auto_complete.gd")

var editor: CodeEdit
var _parse_worker: ParseWorker
var _editor_settings: ClydeEditorSettings
var _auto_complete: AutoComplete

var _parsed_doc: Dictionary
var _error_lines: Dictionary = {}

var _is_new_parsing_execution: bool = false


func _init(code_edit: CodeEdit, settings: ClydeEditorSettings, parse_on_change: bool = false) -> void:
	editor = code_edit
	_editor_settings = settings
	_auto_complete = AutoComplete.new(settings)
	if parse_on_change:
		_setup_parse_worker()
		_on_text_changed.call_deferred()


func get_code_edit() -> CodeEdit:
	return editor


func get_parsed_document() -> Dictionary:
	return _parsed_doc


func _setup_parse_worker() -> void:
	_parse_worker = ParseWorker.new()
	_parse_worker.processing_finished.connect(_on_parsing_finished)
	_parse_worker.processing_failed.connect(_on_parsing_failed)

	var debouncer: Debouncer = Debouncer.new()
	editor.add_child(debouncer)
	var debounced_change: Callable = debouncer.debounced(_on_text_changed, 0.8)
	editor.text_changed.connect(debounced_change)

	editor.set_tooltip_request_func(_on_tooltip_request)

	editor.symbol_lookup_on_click = true
	editor.symbol_lookup.connect(_on_symbol_lookup)
	editor.symbol_validate.connect(_on_symbol_validate)

	editor.code_completion_enabled = true
	editor.code_completion_prefixes = _auto_complete.auto_complete_prefixes
	editor.code_completion_requested.connect(_on_code_completion_requested)
	editor.delimiter_strings = []
	editor.gutters_draw_executing_lines = true


func _on_parsing_finished() -> void:
	_parsed_doc = _parse_worker.get_parse_result()
	_clear_errors()
	parsing_finished.emit()

func _on_parsing_failed(result) -> void:
	if _is_new_parsing_execution:
		_is_new_parsing_execution = false
		_clear_errors()
	_set_error(result)
	parsing_failed.emit(result)


func _on_text_changed() -> void:
	_is_new_parsing_execution = true
	_clear_errors()
	_parse_worker.parse(editor.text)


func _clear_errors() -> void:
	if _error_lines.is_empty():
		return
	for line_number in _error_lines:
		if line_number < editor.get_line_count():
			editor.set_line_background_color.call_deferred(line_number, Color(0, 0, 0, 0))
	_error_lines = {}


func _set_error(error: Dictionary) -> void:
	# skip line already with error to prevent too much noise
	if _error_lines.has(error.line):
		return

	if error.reason == "unexpected_token":
		_error_lines[error.line] = "Unexpected token '%s'. Expected: %s" % [
			error.friendly_token_name,
			" , ".join(error.expected_hints)
		]
	else:
		_error_lines[error.line] = error.message

	editor.set_line_background_color.call_deferred(
		error.line,
		_editor_settings.editor_color_scheme().error_line
	)


func _on_tooltip_request(_hovered_word: String) -> Variant:
	var hover_pos = _get_hover_position()
	if _error_lines.has(hover_pos.y):
		return _error_lines[hover_pos.y]
	return ""


func _on_symbol_validate(symbol: String):
	var hover_pos = _get_hover_position()
	var text = editor.get_line(hover_pos.y)

	var divert = _find_divert_with_text(symbol, text)
	if divert != null:
		editor.set_symbol_lookup_word_as_valid(true)


func _on_symbol_lookup(symbol: String, line: int, column: int):
	if _parsed_doc == null:
		return
	_handle_go_to_block_from_divert(symbol, line, column)


func _handle_go_to_block_from_divert(symbol: String, line: int, column: int) -> void:
	var text = editor.get_line(line)
	var result: RegExMatch = _find_divert_with_text(symbol, text)
	if result == null:
		return

	var found = result.get_string().substr(2).strip_edges()

	for b in _parsed_doc.blocks:
		if b.name == found:
			go_to_position(b.meta.line, b.meta.column)
			break


func _get_hover_position() -> Vector2i:
	return editor.get_line_column_at_pos(editor.get_local_mouse_pos())


func _find_divert_with_text(symbol: String, text: String):
	var identifier = RegEx.create_from_string("-> [A-Z|a-z|0-9|_| ]*%s[A-Z|a-z|0-9|_| ]*" % symbol)
	return identifier.search(text)


func _on_code_completion_requested() -> void:
	_auto_complete.trigger_auto_complete(editor, _parsed_doc)


func go_to_position(line: int, column: int, adjust_viewport: bool = false):
	editor.set_caret_line(line, adjust_viewport)
	editor.set_caret_column(column)


func toggle_comment() -> void:
	editor.begin_complex_operation()
	var comment_symbol = "--"
	var operation = null

	for caret_index in range(0, editor.get_caret_count()):
		var from = 0
		var to = 0
		if editor.has_selection(caret_index):
			from = editor.get_selection_from_line(caret_index)
			to = editor.get_selection_to_line(caret_index) + 1
		else:
			from = editor.get_caret_line(caret_index)
			to = from + 1

		for line in range(from, to):
			var line_text = editor.get_line(line)
			# comment toggle is based on first line in selection
			if operation == null:
				operation = "del" if line_text.begins_with(comment_symbol) else "add"
#
			if operation == "add":
				editor.set_line(line, comment_symbol + line_text)
			elif line_text.begins_with(comment_symbol):
				editor.set_line(line, line_text.substr(comment_symbol.length()))

	editor.end_complex_operation()


func set_executing_line(line: int) -> void:
	editor.clear_executing_lines()
	editor.set_line_as_executing(line, true)
	editor.set_caret_line(line)
	editor.center_viewport_to_caret()


func clear_executing_line() -> void:
	editor.clear_executing_lines()
