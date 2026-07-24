@tool
extends CodeEdit

signal search_requested
signal parsing_finished
signal parsing_failed(result: Dictionary)

const Settings = preload("../config/settings.gd")
const Shortcuts = preload("../config/shortcuts.gd")
const DialogueEditorDecorator = preload("./dialogue_editor_decorator.gd")
const ClydeSyntaxHighlighter = preload("./clyde_syntax_highlighter.gd")

var _settings: Settings

var editor_theme_config

var _shortcuts = []

var _should_follow_execution = true

var editor: DialogueEditorDecorator

func setup(settings: Settings):
	_settings = settings
	editor = DialogueEditorDecorator.new(self, _settings, true)
	editor_theme_config = _load_theme_config()
	syntax_highlighter = ClydeSyntaxHighlighter.new()

	_settings.settings_changed.connect(_on_settings_changed)

	editor.parsing_finished.connect(func(): parsing_finished.emit.call_deferred())
	editor.parsing_failed.connect(func(result): parsing_failed.emit.call_deferred(result))

	_load_text_editor_config()
	_load_shortcuts()


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


func _start_search():
	search_requested.emit()


func go_to_position(line: int, column: int, adjust_viewport: bool = false):
	set_caret_line(line, adjust_viewport)
	set_caret_column(column)


func get_parsed_document() -> Dictionary:
	return editor.get_parsed_document()


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
	editor.toggle_comment()


func _font_size_up():
	_settings.change_font_size(+1)


func _font_size_down():
	_settings.change_font_size(-1)


func _font_reset():
	_settings.clear_font_size()


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
	var column = get_caret_column() - search_obj.text.length() - 1
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
