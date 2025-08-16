@tool
extends CodeEdit

signal finished_change
signal search_requested

const Settings = preload("../config/settings.gd")
const Shortcuts = preload("../config/shortcuts.gd")
const ClydeSyntaxHighlighter = preload("./clyde_syntax_highlighter.gd")

var _settings = Settings.new()

var editor_theme_config

var _time_since_last_change = 0.0

var _errors = []

var _parsed_doc = null

var _shortcuts = []

var _should_follow_execution = true


func _ready():
	editor_theme_config = _load_theme_config()
	syntax_highlighter = ClydeSyntaxHighlighter.new()

	_settings.settings_changed.connect(_on_settings_changed)
	_load_text_editor_config()
	_load_shortcuts()


func _process(delta):
	if _should_trigger_change:
		_time_since_last_change += delta
		if _time_since_last_change >= 2.0:
			_notify_change()


func _load_text_editor_config():
	var settings = _settings.editor_settings()
	self.auto_brace_completion_enabled = settings.auto_brace_completion_enabled
	self.auto_brace_completion_highlight_matching = settings.auto_brace_completion_highlight_matching
	self.code_completion_enabled = settings.code_completion_enabled
	self.code_completion_prefixes = ["==", "->", "#", "$", "&", "(", "( shuffle"]
	self.gutters_draw_line_numbers = settings.gutters_draw_line_numbers
	self.gutters_zero_pad_line_numbers = settings.gutters_zero_pad_line_numbers
	self.indent_automatic = settings.indent_automatic
	self.indent_size = settings.indent_size
	self.indent_use_spaces = settings.indent_use_spaces
	self.line_length_guidelines = settings.line_length_guidelines
	self.autowrap_mode = settings.autowrap_mode
	self.caret_blink = settings.caret_blink
	self.caret_blink_interval = settings.caret_blink_interval
	#self.caret_move_on_right_click = settings.get_setting("")
	self.caret_type = settings.caret_type
	self.drag_and_drop_selection_enabled = settings.drag_and_drop_selection_enabled
	#self.draw_control_chars = settings.get_setting("")
	self.draw_spaces = settings.draw_spaces
	self.draw_tabs = settings.draw_tabs
	self.highlight_current_line = settings.highlight_current_line
	#self.middle_mouse_paste_enabled = settings.get_setting("")
	self.minimap_draw = settings.minimap_draw
	self.minimap_width = settings.minimap_width
	self.scroll_past_end_of_file = settings.scroll_past_end_of_file
	self.scroll_smooth = settings.scroll_smooth
	self.scroll_v_scroll_speed = settings.scroll_v_scroll_speed
	self.wrap_mode = settings.wrap_mode

	add_theme_font_size_override("font_size", settings.font_size)

	refresh_config()

func _load_theme_config():
	return {
		"color_scheme": _settings.editor_color_scheme()
	}


func _load_shortcuts():
	var shortcuts = Shortcuts.new()
	_shortcuts = [
		{
			"shortcut": shortcuts.get_shortcut_for_command(Shortcuts.CMD_EDITOR_TOGGLE_COMMENT),
			"handler": _toggle_comment,
		},
		{
			"shortcut": shortcuts.get_shortcut_for_command(Shortcuts.CMD_EDITOR_FONT_SIZE_UP),
			"handler": _font_size_up,
		},
		{
			"shortcut": shortcuts.get_shortcut_for_command(Shortcuts.CMD_EDITOR_FONT_SIZE_DOWN),
			"handler": _font_size_down,
		},
		{
			"shortcut": shortcuts.get_shortcut_for_command(Shortcuts.CMD_EDITOR_FONT_SIZE_RESET),
			"handler": _font_reset,
		},
		{
			"shortcut": shortcuts.get_shortcut_for_command(Shortcuts.CMD_EDITOR_SEARCH),
			"handler": _start_search,
		},
	]


func _on_settings_changed():
	editor_theme_config = _load_theme_config()
	_load_text_editor_config()


var _should_trigger_change = false
func _on_text_changed():
	_should_trigger_change = true
	_time_since_last_change = 0
	request_code_completion()


func _notify_change():
	_should_trigger_change = false
	finished_change.emit()


func _start_search():
	search_requested.emit()


func go_to_position(line: int, column: int, adjust_viewport: bool = false):
	set_caret_line(line, adjust_viewport)
	set_caret_column(column)


func add_error(error):
	set_line_background_color(error.line, editor_theme_config.color_scheme.error_line)
	_errors.push_back(error.line)


func clear_errors():
	var errors_to_remove = _errors
	_errors = []
	for error_line in errors_to_remove:
		if error_line < get_line_count():
			set_line_background_color(error_line, Color(0, 0, 0, 0))


func set_parsed_document(parsed: Dictionary):
	_parsed_doc = parsed


var _before_doc_completion_handler = {
	"( ": _variation_autocompletion,
}
var _after_doc_completion_handler = {
	"-> ": _block_autocompletion,
}

func _request_code_completion(force: bool) -> void:
	var line_number = get_caret_line()
	var column_number = get_caret_column()
	var line = get_line(line_number)

	for rule in _before_doc_completion_handler:
		if line.contains(rule) and _before_doc_completion_handler[rule].call(line, column_number):
			return

	# bellow here any rule that requires document lookup
	if _parsed_doc == null:
		return

	for rule in _after_doc_completion_handler:
		if line.contains(rule) and _after_doc_completion_handler[rule].call(line, column_number):
			return


func _block_autocompletion(line: String, caret_column: int) -> bool:
	var divert_pos = line.find("->")
	if caret_column < divert_pos:
		return false
	var block_name = line.substr(divert_pos + 3, caret_column).strip_edges(true, false)
	var has_options_available = false
	for block in _parsed_doc.blocks:
		if block_name.is_empty() or block.name.contains(block_name):
			has_options_available = true
			add_code_completion_option(
				CodeEdit.KIND_MEMBER,
				block.name, # display
				block.name, # to insert
				editor_theme_config.color_scheme.identifier, # color
				get_theme_icon("MoveRight", "EditorIcons"),
				{ "replace": { "from": divert_pos + 3, "to": caret_column }}
			)
	# default END divert
	add_code_completion_option(
		CodeEdit.KIND_MEMBER,
		"END", # display
		"END", # to insert
		editor_theme_config.color_scheme.keyword, # color
		get_theme_icon("PickerShapeRectangleWheel", "EditorIcons"),
		{ "replace": { "from": divert_pos + 3, "to": caret_column }}
	)
	if has_options_available:
		update_code_completion_options(true)
	else:
		cancel_code_completion()

	return true


const variation_options = [
	"cycle",
	"sequence",
	"once",
	"shuffle",
	"shuffle cycle",
	"shuffle once",
	"shuffle sequence",
]


func _variation_autocompletion(line: String, carret_column: int) -> bool:
	var symbol_pos = line.find("(")
	if carret_column < symbol_pos:
		return false

	if not line.substr(0, symbol_pos).strip_edges().is_empty():
		cancel_code_completion()
		return false

	var variation_type = line.substr(symbol_pos + 2).strip_edges(true, false).replace(")", "")
	var is_empty_type = variation_type.strip_edges().is_empty()
	var has_options_available = false
	for option in variation_options:
		if is_empty_type or option.contains(variation_type):
			has_options_available = true
			add_code_completion_option(
				CodeEdit.KIND_CONSTANT,
				option, # display
				option, # to insert
				editor_theme_config.color_scheme.keyword, # color
				get_theme_icon("KeyValue", "EditorIcons"),
				{ "replace": { "from": symbol_pos + 2, "to": carret_column }}
			)
	if has_options_available:
		update_code_completion_options(true)
	else:
		cancel_code_completion()
	return true


func _confirm_code_completion(replace: bool) -> void:
	begin_complex_operation()
	var completion = get_code_completion_option(get_code_completion_selected_index())
	var to_replace = get_word_under_caret()

	if completion.default_value.has("replace"):
		var current_line = get_caret_line()
		remove_text(current_line, completion.default_value.replace.from, current_line, completion.default_value.replace.to)
		set_caret_column(completion.default_value.replace.from)
	insert_text_at_caret(completion.insert_text)
	end_complex_operation()

	call_deferred("cancel_code_completion")


# this method's default implementation does some string handling
# which is adding quotes to the auto completion options sometimes depending
# on where in the file it's happening. Overriding to remove default behaviour.
func _filter_code_completion_candidates(candidates: Array) -> Array:
	return candidates


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		for s in _shortcuts:
			if s.shortcut.matches_event(event):
				s.handler.call()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event.ctrl_pressed or event.meta_pressed):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			_font_size_up()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			_font_size_down()
			get_viewport().set_input_as_handled()


func _toggle_comment():
	begin_complex_operation()
	var comment_symbol = "--"
	var operation = null

	for caret_index in range(0, get_caret_count()):
		var from = 0
		var to = 0
		if has_selection(caret_index):
			from = get_selection_from_line(caret_index)
			to = get_selection_to_line(caret_index) + 1
		else:
			from = get_caret_line(caret_index)
			to = from + 1

		for line in range(from, to):
			var line_text = get_line(line)
			# comment toggle is based on first line in selection
			if operation == null:
				operation = "del" if line_text.begins_with(comment_symbol) else "add"

			if operation == "add":
				set_line(line, comment_symbol + line_text)
			elif line_text.begins_with(comment_symbol):
				set_line(line, line_text.substr(comment_symbol.length()))

	end_complex_operation()


func _font_size_up():
	_settings.change_font_size(+1)


func _font_size_down():
	_settings.change_font_size(-1)


func _font_reset():
	_settings.font_size()


func _on_symbol_lookup(symbol, line, column):
	var text = get_line(line).substr(column + 2)
	var char_index = text.find("<-")
	if char_index != -1:
		text = text.substr(0, char_index).strip_edges()

	if _parsed_doc != null:
		for b in _parsed_doc.blocks:
			if b.name == text:
				go_to_position(b.meta.line, b.meta.column)
				break


func _on_symbol_validate(symbol):
	if symbol == "->":
		set_symbol_lookup_word_as_valid(true)


func clear_search():
	deselect()
	set_search_text("")


func set_search(search_info: Dictionary, should_go_to_position: bool = false, backwards: bool = false):
	if search_info.text == "":
		clear_search()
		return
	deselect()
	var flags = _get_search_flags(search_info, backwards)
	set_search_flags(flags)
	set_search_text(search_info.text)

	if should_go_to_position:
		var p = search(search_info.text, flags, get_caret_line(), get_caret_column())
		if p.x != -1:
			go_to_position(p.y, p.x, true)
			select(p.y, p.x, p.y, p.x + search_info.text.length())


func _get_search_flags(search: Dictionary, backwards: bool = false):
	var search_flags = 0
	if search.match_case:
		search_flags += SEARCH_MATCH_CASE
	if search.whole_words:
		search_flags += SEARCH_WHOLE_WORDS
	if backwards:
		search_flags += SEARCH_BACKWARDS

	return search_flags


func search_next(search_obj: Dictionary):
	var column = get_caret_column() + 1
	var line = get_caret_line()
	if column >= get_line(line).length():
		column = 0
		line += 1
	set_caret_column(column)
	set_caret_line(line)
	set_search(search_obj, true)


func search_previous(search_obj: Dictionary):
	var column = get_caret_column() - 1
	var line = get_caret_line()
	if column < 0:
		line -= 1
		column = get_line(line).length() - 1
	set_caret_column(column)
	set_caret_line(line)
	set_search(search_obj, true, true)


func set_executing_line(line: int):
	clear_executing_lines()
	set_line_as_executing(line, true)
	if _should_follow_execution:
		set_caret_line(line)
		center_viewport_to_caret()


func refresh_config():
	_should_follow_execution = _settings.get_config(_settings.EDITOR_CFG_EDITOR_FOLLOW_EXECUTION, true)
