@tool
extends HBoxContainer

signal variable_changed(var_name: String, value)
signal external_variable_changed(var_name: String, value)

const DebugEntryActions = preload("./debug_entry_actions.tscn")
const InterfaceText = preload("../config/interface_text.gd")
const DebugVariables = preload("./debug_dock_variables.gd")
const DebugHistoryEntries = preload("./debug_dock_history_entries.gd")

@onready var _var_tabs: TabContainer = $HSplitContainer/var_tabs
@onready var _debug_entries: GridContainer = $HSplitContainer/var_tabs/variables/ScrollContainer/DebugEntries
@onready var _ext_var_entries: GridContainer = $HSplitContainer/var_tabs/external_variables/ScrollContainer/DebugEntries
@onready var _event_entries: GridContainer = $HSplitContainer/history/ScrollContainer/EventEntries
@onready var _event_scrollbar: VScrollBar = _event_entries.get_parent().get_v_scroll_bar()
@onready var _variable_scrollbar: VScrollBar = _debug_entries.get_parent().get_v_scroll_bar()
@onready var _external_variable_scrollbar: VScrollBar = _ext_var_entries.get_parent().get_v_scroll_bar()
@onready var _add_var_btn: Button = $HSplitContainer/var_tabs/variables/MarginContainer/add_btn
@onready var _add_ext_var_btn: Button = $HSplitContainer/var_tabs/external_variables/MarginContainer/add_btn

@onready var _variables = DebugVariables.new(_debug_entries, _add_var_btn)
@onready var _external_variables = DebugVariables.new(_ext_var_entries, _add_ext_var_btn)

@onready var _debug_history = DebugHistoryEntries.new(_event_entries)

func _ready():
	_event_scrollbar.changed.connect(_on_scrollbar_changed)
	_variable_scrollbar.changed.connect(_on_var_scrollbar_changed)
	_external_variable_scrollbar.changed.connect(_on_ext_var_scrollbar_changed)

	_var_tabs.set_tab_title(0, InterfaceText.get_string(InterfaceText.KEY_DEBUG_VARIABLES_LABEL))
	_var_tabs.set_tab_title(1, InterfaceText.get_string(InterfaceText.KEY_DEBUG_EXT_VARIABLES_LABEL))

	$HSplitContainer/history/Label.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_HISTORY_LABEL)
	_add_var_btn.icon = get_theme_icon("Add", "EditorIcons")
	_add_var_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_ADD_VARIABLE)
	_add_ext_var_btn.icon = get_theme_icon("Add", "EditorIcons")
	_add_ext_var_btn.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_ADD_VARIABLE)

	_variables.variable_changed.connect(_on_variable_changed)
	_external_variables.variable_changed.connect(_on_external_variable_changed)


func set_variable(var_name: String, var_value, old_value = null):
	_variables.set_variable(var_name, var_value, old_value)
	_debug_history.add_variable_record(var_name, var_value, old_value)


func set_external_variable(var_name: String, var_value, old_value = null):
	_external_variables.set_variable(var_name, var_value, old_value)
	_debug_history.add_variable_record(var_name, var_value, old_value, InterfaceText.KEY_DEBUG_EXTERNAL_VARIABLE_LABEL)


func load_data(data: Dictionary, should_clear_events: bool = false):
	_variables.clear_entries()

	if should_clear_events:
		_debug_history.clear_event_history()

	_variables.load_data(data)


func load_external_variables(external_variables: Dictionary):
	_external_variables.load_data(external_variables)


func record_event(event_name: String, parameters: Array):
	_debug_history.record_event(event_name, parameters)


func _on_scrollbar_changed():
	var scroll_value = _event_scrollbar.max_value
	var scroll_container = _event_entries.get_parent()
	if scroll_value != scroll_container.scroll_vertical:
		scroll_container.scroll_vertical = scroll_value


func _on_var_scrollbar_changed():
	var scroll_value = _variable_scrollbar.max_value
	var scroll_container = _debug_entries.get_parent()
	if scroll_value != scroll_container.scroll_vertical:
		scroll_container.scroll_vertical = scroll_value


func _on_ext_var_scrollbar_changed():
	var scroll_value = _external_variable_scrollbar.max_value
	var scroll_container = _ext_var_entries.get_parent()
	if scroll_value != scroll_container.scroll_vertical:
		scroll_container.scroll_vertical = scroll_value


func _on_add_btn_pressed():
	_variables.start_add_variable_mode()


func _on_add_external_btn_pressed() -> void:
	_external_variables.start_add_variable_mode()


func _on_variable_changed(var_name: String, value: Variant):
	variable_changed.emit(var_name, value)


func _on_external_variable_changed(var_name: String, value: Variant):
	external_variable_changed.emit(var_name, value)
