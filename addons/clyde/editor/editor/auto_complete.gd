extends RefCounted

const ClydeEditorSettings = preload("../config/settings.gd")

const auto_complete_prefixes = ["->", "(", "( shuffle"]

var _parse_not_required_handlers = {
	"( ": _variation_autocompletion,
}
var _parsed_required_handlers = {
	"-> ": _block_autocompletion,
}

const variation_options = [
	"cycle",
	"sequence",
	"once",
	"shuffle",
	"shuffle cycle",
	"shuffle once",
	"shuffle sequence",
]

var _settings: ClydeEditorSettings

func _init(settings: ClydeEditorSettings) -> void:
	_settings = settings


func trigger_auto_complete(editor: CodeEdit, parsed_doc: Dictionary) -> void:
	var line_number = editor.get_caret_line()
	var column_number = editor.get_caret_column()
	var line = editor.get_line(line_number)

	for rule in _parse_not_required_handlers:
		if line.contains(rule) and _parse_not_required_handlers[rule].call(editor, line, column_number):
			return

	# bellow this check goes any rules that require document lookup
	if parsed_doc == null:
		return

	for rule in _parsed_required_handlers:
		if line.contains(rule) and _parsed_required_handlers[rule].call(editor, parsed_doc, line, column_number):
			return


func _block_autocompletion(editor: CodeEdit, parsed_doc: Dictionary, line: String, caret_column: int) -> bool:
	var divert_pos = line.find("->")
	if caret_column < divert_pos:
		return false
	var block_name = line.substr(divert_pos + 3, caret_column).strip_edges(true, false)
	var has_options_available = false
	for block in parsed_doc.blocks:
		if block_name.is_empty() or block.name.contains(block_name):
			has_options_available = true
			editor.add_code_completion_option(
				CodeEdit.KIND_MEMBER,
				block.name, # display
				block.name, # to insert
				_settings.editor_color_scheme().identifier,
				_settings.get_theme_icon("autocomplete_block"),
			)
	# default END divert
	editor.add_code_completion_option(
		CodeEdit.KIND_MEMBER,
		"END", # display
		"END", # to insert
		_settings.editor_color_scheme().identifier,
		_settings.get_theme_icon("autocomplete_block_end"),
	)
	if has_options_available:
		editor.update_code_completion_options(true)
	else:
		editor.cancel_code_completion()

	return true


func _variation_autocompletion(editor: CodeEdit, line: String, caret_column: int) -> bool:
	var symbol_pos = line.find("(")
	if caret_column < symbol_pos:
		return false

	if not line.substr(0, symbol_pos).strip_edges().is_empty():
		editor.cancel_code_completion()
		return false

	var variation_type = line.substr(symbol_pos + 2).strip_edges(true, false).replace(")", "")
	var is_empty_type = variation_type.strip_edges().is_empty()
	var has_options_available = false
	for option in variation_options:
		if is_empty_type or option.contains(variation_type):
			has_options_available = true
			editor.add_code_completion_option(
				CodeEdit.KIND_CONSTANT,
				option, # display
				option, # to insert
				_settings.editor_color_scheme().keyword,
				_settings.get_theme_icon("autocomplete_variation"),
			)
	if has_options_available:
		editor.update_code_completion_options(true)
	else:
		editor.cancel_code_completion()
	return true
