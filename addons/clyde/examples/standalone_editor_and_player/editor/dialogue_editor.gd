extends CodeEdit

signal parsing_finished
signal parsing_failed(result: Dictionary)

const Settings = preload("res://addons/clyde/editor/config/settings.gd")
const DialogueEditorDecorator = preload("res://addons/clyde/editor/editor/dialogue_editor_decorator.gd")
const Shortcuts = preload("./shortcuts.gd")
const ClydeSyntaxHighlighter = preload("./clyde_syntax_highlighter.gd")

var _settings: Settings

var editor_theme_config

var _shortcuts = []

var _should_follow_execution = true

var editor: DialogueEditorDecorator

const DEFAULT_SETTINGS = {
	"auto_brace_completion_enabled": true,
	"auto_brace_completion_highlight_matching": true,
	"code_completion_enabled": true,
	"gutters_draw_line_numbers": true,
	"gutters_zero_pad_line_numbers": false,
	"line_length_guideline_hard_column": 100,
	"line_length_guideline_soft_column": 80,
	"indent_automatic": true,
	"indent_size": 4,
	"indent_use_spaces": false,
	"autowrap_mode": 3,
	"caret_blink": true,
	"caret_blink_interval": 0.5,
	"caret_type": 0,
	"drag_and_drop_selection_enabled": true,
	"draw_spaces": true,
	"draw_tabs": true,
	"highlight_current_line": true,
	"minimap_draw": true,
	"minimap_width": 80,
	"scroll_past_end_of_file": true,
	"scroll_smooth": true,
	"scroll_v_scroll_speed": 80,
	"wrap_mode": 0,
	"font_size": 14.0,
}

const DEFAULT_COLOR_SCHEME = {
	"background": "#1d2229ff",
	"current_line": "#ffffff12",
	"error_line": "#ff786b4d",
	"comment": "#cdcfd280",
	"identifier": "#bce0ffff",
	"symbol": "#abc9ffff",
	"text": "#cdcfd2ff",
	"tag": "#57b3ffff",
	"keyword": "#ff7085ff",
	"operator": "#ff8cccff",
	"number_literal": "#a1ffe0ff",
	"boolean_literal": "#ff7085ff",
	"string_literal": "#ffeda1ff",
	"warning_color": "#b89c7aff",
	"success_color": "#cdf8d2bf",
	"error_color": "#ff786b4d",
}

var _current_font_size: float = DEFAULT_SETTINGS.font_size

func setup(settings: Settings):
	_settings = settings
	editor = DialogueEditorDecorator.new(self, _settings, true)
	editor_theme_config = _load_theme_config()
	syntax_highlighter = ClydeSyntaxHighlighter.new()

	editor.parsing_finished.connect(func(): parsing_finished.emit.call_deferred())
	editor.parsing_failed.connect(func(result): parsing_failed.emit.call_deferred(result))

	_load_text_editor_config()
	_load_shortcuts()


func _load_text_editor_config():
	self.auto_brace_completion_enabled = DEFAULT_SETTINGS.auto_brace_completion_enabled
	self.auto_brace_completion_highlight_matching = DEFAULT_SETTINGS.auto_brace_completion_highlight_matching
	self.gutters_draw_line_numbers = DEFAULT_SETTINGS.gutters_draw_line_numbers
	self.gutters_zero_pad_line_numbers = DEFAULT_SETTINGS.gutters_zero_pad_line_numbers
	self.indent_automatic = DEFAULT_SETTINGS.indent_automatic
	self.indent_size = DEFAULT_SETTINGS.indent_size
	self.indent_use_spaces = DEFAULT_SETTINGS.indent_use_spaces
	self.autowrap_mode = DEFAULT_SETTINGS.autowrap_mode
	self.caret_blink = DEFAULT_SETTINGS.caret_blink
	self.caret_blink_interval = DEFAULT_SETTINGS.caret_blink_interval
	self.caret_type = DEFAULT_SETTINGS.caret_type
	self.drag_and_drop_selection_enabled = DEFAULT_SETTINGS.drag_and_drop_selection_enabled
	self.draw_spaces = DEFAULT_SETTINGS.draw_spaces
	self.draw_tabs = DEFAULT_SETTINGS.draw_tabs
	self.highlight_current_line = DEFAULT_SETTINGS.highlight_current_line
	self.minimap_draw = DEFAULT_SETTINGS.minimap_draw
	self.minimap_width = DEFAULT_SETTINGS.minimap_width
	self.scroll_past_end_of_file = DEFAULT_SETTINGS.scroll_past_end_of_file
	self.scroll_smooth = DEFAULT_SETTINGS.scroll_smooth
	self.scroll_v_scroll_speed = DEFAULT_SETTINGS.scroll_v_scroll_speed
	self.wrap_mode = DEFAULT_SETTINGS.wrap_mode

	add_theme_font_size_override("font_size", DEFAULT_SETTINGS.font_size)

	_should_follow_execution = true


func _load_theme_config():
	var colors: Dictionary[String, Color] = {}

	for c in DEFAULT_COLOR_SCHEME:
		colors[c] = Color(DEFAULT_COLOR_SCHEME[c])

	return {
		"color_scheme": colors
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
	]


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
	_current_font_size += 1
	_update_editor_font_size(_current_font_size)


func _font_size_down():
	_current_font_size -= 1
	_update_editor_font_size(_current_font_size)


func _font_reset():
	_current_font_size = DEFAULT_SETTINGS.font_size
	_update_editor_font_size(_current_font_size)


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


func _update_editor_font_size(font_size: float) -> void:
	add_theme_font_size_override("font_size", font_size)
