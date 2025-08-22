@tool
extends MarginContainer

signal content_finished_changing(dialogue_key: String, content: Dictionary)
signal dialogue_reset(dialogue_key)
signal position_selected(dialogue_key: String, line: int, column: int)
signal toggle_debug_panel(is_visible: bool)
signal dialogue_mem_clean
signal variable_changed(var_name, value, old_value)
signal external_variable_changed(var_name, value, old_value)
signal event_triggered(event_name, parameters)
signal close_triggered
signal dock_button_pressed

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")
const DialogueBubble = preload("./dialogue_bubble.tscn")
const DialogueEventBubble = preload("./dialogue_event_bubble.tscn")

var _settings = Settings.new()

@onready var _dialogue_title_field: Label = $HBoxContainer/VBoxContainer/MarginContainer/dialogue_name
@onready var _lines_container = $HBoxContainer/VBoxContainer/LinesMargin/lines/dialogue_lines
@onready var _scroll_container = $HBoxContainer/VBoxContainer/LinesMargin/lines

@onready var _restart_btn = $HBoxContainer/VBoxContainer/actions/restart
@onready var _next_line_btn = $HBoxContainer/VBoxContainer/actions/next_line
@onready var _forward_btn = $HBoxContainer/VBoxContainer/actions/forward
@onready var _polterigeist_btn = $HBoxContainer/VBoxContainer/actions/poltergeist
@onready var _clear_mem_btn = $HBoxContainer/VBoxContainer/actions/clear_mem
@onready var _multi_single_btn := $HBoxContainer/VBoxContainer/actions/multi_single
@onready var _show_meta_btn = $HBoxContainer/VBoxContainer/actions/show_meta
@onready var _show_debug_btn = $HBoxContainer/VBoxContainer/actions/show_debug
@onready var _close_btn = $HBoxContainer/VBoxContainer/MarginContainer/HBoxContainer/close
@onready var _dock_btn = $HBoxContainer/VBoxContainer/MarginContainer/HBoxContainer/dock

@onready var _block_selection_field = $HBoxContainer/VBoxContainer/actions/Block
@onready var _scrollbar: VScrollBar = _scroll_container.get_v_scroll_bar()

var _dialogue: ClydeDialogue
var _dialogue_key: String
var _dialogue_has_ended = false
var _is_waiting_for_choice = false
var _dialogue_data = {}
var _external_variables := {}
var _has_external_variables_changed := false

func _ready():
	_load_config()
	_scrollbar.changed.connect(_on_scrollbar_changed)
	_setup_actions()
	_add_initial_line()


func _setup_actions():
	_setup_strings()
	_setup_icons()
	clear_dialogue()


func _setup_strings():
	_restart_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_RESTART_TOOLTIP)
	_next_line_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_NEXT_LINE_TOOLTIP)
	_forward_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_FORWARD_TOOLTIP)
	_polterigeist_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_POLTERGEIST_TOOLTIP)
	_clear_mem_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_CLEAR_MEM_TOOLTIP)
	_multi_single_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_BALLOONS_TOOLTIP)
	_show_meta_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_SHOW_META_TOOLTIP)
	_show_debug_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_SHOW_DEBUG_TOOLTIP)

	_block_selection_field.add_item(InterfaceText.get_string(InterfaceText.KEY_DEFAULT_BLOCK))
	_block_selection_field.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_PLAYER_BLOCK_SELECTION_TOOLTIP)

	_dialogue_title_field.text = InterfaceText.get_string(InterfaceText.KEY_NO_DIALOGUE)


func _setup_icons():
	_restart_btn.icon = get_theme_icon("RotateLeft", "EditorIcons")
	_next_line_btn.icon = get_theme_icon("Play", "EditorIcons")
	_forward_btn.icon = get_theme_icon("TransitionEnd", "EditorIcons")
	_polterigeist_btn.icon = load("res://addons/clyde/editor/assets/clyde.svg")
	_clear_mem_btn.icon = get_theme_icon("History", "EditorIcons")
	_multi_single_btn.icon = get_theme_icon("MakeFloating", "EditorIcons")
	_show_meta_btn.icon = get_theme_icon("GuiEllipsis", "EditorIcons")
	_show_debug_btn.icon = get_theme_icon("Debug", "EditorIcons")
	_close_btn.icon = get_theme_icon("Close", "EditorIcons")
	_dock_btn.icon = get_theme_icon("MakeFloating", "EditorIcons")


func _load_config():
	var cfg = _settings.get_editor_config()
	_multi_single_btn.button_pressed = cfg.get(_settings.EDITOR_CFG_PLAYER_SHOW_MULTI_BUBBLE, true)
	_show_meta_btn.button_pressed = cfg.get(_settings.EDITOR_CFG_PLAYER_SHOW_METADATA, false)
	_external_variables = _settings.get_external_variables()


func set_dialogue(key: String, parsed_document: Dictionary):
	# persist previous data
	if _dialogue != null:
		_dialogue_data[_dialogue_key] = _dialogue.get_data()

	_update_external_variables()

	_dialogue_key = key
	_dialogue_title_field.text = key.get_file()
	_dialogue_title_field.tooltip_text = key
	_dialogue = ClydeDialogue.new()
	_dialogue._load_parsed_doc(parsed_document)
	_restart_btn.disabled = false
	_next_line_btn.disabled = false
	_forward_btn.disabled = false
	_polterigeist_btn.disabled = false
	_block_selection_field.disabled = false
	_dialogue_has_ended = false
	_is_waiting_for_choice = false
	_load_blocks(parsed_document)

	if _dialogue_data.has(key):
		_dialogue.load_data(_dialogue_data[key])

	_dialogue.variable_changed.connect(_on_variable_changed)
	_dialogue.event_triggered.connect(_on_event_triggered)

	_dialogue.on_external_variable_fetch(_external_variable_fetch)
	_dialogue.on_external_variable_update(_external_variable_update)

	_remove_lines()
	_add_dialogue_loaded_line()


func _load_blocks(parsed_document: Dictionary):
	_block_selection_field.clear()

	_block_selection_field.add_item(InterfaceText.get_string(InterfaceText.KEY_DEFAULT_BLOCK))
	for b in parsed_document.blocks:
		_block_selection_field.add_item(b.name)


func clear_dialogue():
	_dialogue = null
	_restart_btn.disabled = true
	_next_line_btn.disabled = true
	_forward_btn.disabled = true
	_polterigeist_btn.disabled = true
	_block_selection_field.disabled = true
	_dialogue_has_ended = false
	_is_waiting_for_choice = false


func _on_block_item_selected(index):
	if _dialogue == null:
		return

	if index == 0:
		_add_start_dialogue_line(null)
		_dialogue.start()
		return
	var block_name = _block_selection_field.get_item_text(index)
	_dialogue.start(block_name)
	_add_start_dialogue_line(block_name)


func _on_restart_pressed():
	dialogue_reset.emit(_dialogue_key)
	_remove_lines()
	_on_block_item_selected(_block_selection_field.selected)


func _on_next_line_pressed():
	if _is_waiting_for_choice:
		return
	var content = _dialogue.get_content()
	_add_dialogue_bubble(content)
	content_finished_changing.emit(_dialogue_key, content)


func _on_forward_pressed():
	if _is_waiting_for_choice:
		return

	var content = _dialogue.get_content()
	_add_dialogue_bubble(content)

	if content.type == "line":
		_on_forward_pressed()
	else:
		content_finished_changing.emit(_dialogue_key, content)


func _on_poltergeist_pressed():
	var content = _dialogue.get_content()
	var bubble = _add_dialogue_bubble(content)

	if content.type == "line":
		_on_poltergeist_pressed()
	elif content.type == "options":
		var choice = randi() % content.options.size()
		_dialogue.choose(choice)
		bubble.set_chosen(choice)
		_on_poltergeist_pressed()
	else:
		content_finished_changing.emit(_dialogue_key, content)


func _on_clear_mem_pressed():
	_dialogue_data = {}
	if _dialogue != null:
		_dialogue.clear_data()
		dialogue_mem_clean.emit()
	_on_restart_pressed()


func _on_multi_single_toggled(toggled_on):
	if toggled_on:
		_show_all_lines()
	else:
		_hide_previous_lines()
	_settings.set_config(_settings.EDITOR_CFG_PLAYER_SHOW_MULTI_BUBBLE, toggled_on)


func _on_show_meta_toggled(toggled_on):
	if toggled_on:
		for c in get_tree().get_nodes_in_group("clyde_dialogue_line_meta"):
			if c.get_child_count() > 0:
				c.show()
	else:
		for c in get_tree().get_nodes_in_group("clyde_dialogue_line_meta"):
			c.hide()
	_settings.set_config(_settings.EDITOR_CFG_PLAYER_SHOW_METADATA, toggled_on)


func _on_show_debug_toggled(toggled_on):
	toggle_debug_panel.emit(toggled_on)


func _add_start_dialogue_line(block_name):
	_dialogue_has_ended = false
	_is_waiting_for_choice = false
	var message = InterfaceText.get_string(InterfaceText.KEY_PLAYER_DIALOGUE_STARTED)

	_add_event_line(message, block_name)


func _add_dialogue_loaded_line():
	var message = InterfaceText.get_string(InterfaceText.KEY_DIALOGUE_LOADED)
	_add_event_line(message)


func _add_dialogue_bubble(content: Dictionary):
	if content.type == "end":
		if not _dialogue_has_ended:
			_add_dialogue_ended_line()
		return

	if content.type == "options":
		_is_waiting_for_choice = true

	_adjust_previous_line_visibility()

	var bubble = DialogueBubble.instantiate()
	_lines_container.add_child(bubble)
	bubble.set_content(content, _show_meta_btn.button_pressed)
	bubble.bubble_clicked.connect(_on_bubble_clicked)
	bubble.option_selected.connect(_on_option_selected)
	return bubble


func _on_scrollbar_changed():
	var scroll_value = _scrollbar.max_value
	if scroll_value != _scroll_container.scroll_vertical:
		_scroll_container.scroll_vertical = scroll_value


func _show_all_lines():
	for c in _lines_container.get_children():
		c.show()


func _hide_previous_lines():
	if _lines_container.get_child_count() < 2:
		return
	var last
	for c in _lines_container.get_children():
		last = c
		c.hide()
	last.show()


func _adjust_previous_line_visibility():
	if not _multi_single_btn.button_pressed and _lines_container.get_child_count() > 0:
		_lines_container.get_child(_lines_container.get_child_count() -1).hide()


func _add_dialogue_ended_line():
	_dialogue_has_ended = true
	_add_event_line(InterfaceText.get_string(InterfaceText.KEY_DIALOGUE_END), null)
	_update_external_variables()


func _add_event_line(text: String, second_line = null):
	_adjust_previous_line_visibility()
	var bubble = DialogueEventBubble.instantiate()
	_lines_container.add_child(bubble)
	bubble.set_label(text, second_line)


func _remove_lines():
	for c in _lines_container.get_children():
		c.queue_free()


func _on_bubble_clicked(line: int, column: int):
	position_selected.emit(_dialogue_key, line, column)


func _on_option_selected(index):
	_is_waiting_for_choice = false
	_dialogue.choose(index)
	_on_next_line_pressed()


func _gui_input(event):
	if not self.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_next_line_pressed()


func get_data() -> Dictionary:
	if _dialogue != null:
		return _dialogue.get_data().variables
	return {}


func set_variable(var_name: String, value):
	if _dialogue != null:
		_dialogue.set_variable(var_name, value)


func set_external_variable(var_name: String, value):
	_external_variables[var_name] = value
	_has_external_variables_changed = true
	_update_external_variables()


func _on_variable_changed(var_name: String, value, old_value):
	variable_changed.emit(var_name, value, old_value)


func _on_event_triggered(event_name: String, parameters: Array):
	event_triggered.emit(event_name, parameters)


func _add_initial_line():
	var message = InterfaceText.get_string(InterfaceText.KEY_DIALOGUE_NOT_LOADED)
	_add_event_line(message)


func _on_close_button_up():
	_update_external_variables()
	close_triggered.emit()


func _external_variable_fetch(var_name: String) -> Variant:
	return _external_variables.get(var_name, null)


func _external_variable_update(var_name: String, value: Variant) -> void:
	_has_external_variables_changed = true
	var old_value = _external_variables.get(var_name)
	_external_variables[var_name] = value
	external_variable_changed.emit(var_name, value, old_value)


func _update_external_variables():
	if _has_external_variables_changed:
		_settings.set_external_variables(_external_variables)
		_has_external_variables_changed = false


func get_external_variables():
	if _external_variables.is_empty():
		_external_variables = _settings.get_external_variables()

	return _external_variables.duplicate()


func _on_dock_button_up() -> void:
	dock_button_pressed.emit()


func hide_close_button() -> void:
	_close_btn.hide()


func show_close_button() -> void:
	_close_btn.show()
