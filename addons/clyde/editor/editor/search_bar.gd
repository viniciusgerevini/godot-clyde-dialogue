@tool
extends HBoxContainer

signal search_closed
signal search_text_changed(text: String, match_case: bool, whole_words: bool)
signal next_pressed
signal previous_pressed

@onready var _search_input = $search_input
@onready var _previous_btn = $previous
@onready var _next_btn = $next
@onready var _close_btn = $close
@onready var _search_info = $info
@onready var _match_case = $match_case
@onready var _whole_words = $whole_words

# TODO get strigns from interface text


func _ready():
	_setup_icons()


func _setup_icons():
	_close_btn.icon = get_theme_icon("Close", "EditorIcons")
	_previous_btn.icon = get_theme_icon("MoveUp", "EditorIcons")
	_next_btn.icon = get_theme_icon("MoveDown", "EditorIcons")


func focus():
	_search_input.grab_focus()


func _on_close_button_up():
	search_closed.emit()
	hide()


func _on_whole_words_pressed():
	_on_search_input_text_changed(_search_input.text)


func _on_match_case_pressed():
	_on_search_input_text_changed(_search_input.text)


func _on_next_button_up():
	next_pressed.emit()


func _on_previous_button_up():
	previous_pressed.emit()


func _on_search_input_text_changed(new_text):
	search_text_changed.emit(new_text,_match_case.button_pressed, _whole_words.button_pressed)


func _on_search_input_text_submitted(new_text):
	next_pressed.emit()


func _on_search_input_gui_input(event: InputEvent):
	if event is InputEventKey:
		if event.physical_keycode == KEY_ESCAPE:
			_on_close_button_up()
