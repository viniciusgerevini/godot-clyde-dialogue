@tool
extends RefCounted

signal variable_changed(var_name: String, value)

const DebugEntryActions = preload("./debug_entry_actions.tscn")

enum Types {
	BooleanValue,
	NumberValue,
	StringValue,
}

const ADD_VAR_TEMP_NAME = "ADD-VAR"

var _variables := {}
var _is_adding = false

var _var_entries: Node
var _add_var_btn: Button

func _init(var_entries: Node, add_var_btn: Button):
	_var_entries = var_entries
	_add_var_btn = add_var_btn


func load_data(initial_data: Dictionary) -> void:
	for k in initial_data:
		if initial_data[k] != null:
			set_variable(k, initial_data[k])


func set_variable(var_name: String, var_value, old_value = null):
	if not _variables.has(var_name):
		_create_variable_fields(var_name)
	_update_variable(var_name, var_value)


func _create_variable_fields(var_name: String):
	var name_field = _create_name_field(var_name)
	var type_field = _create_type_field()
	var string_field = _create_string_field()
	var number_field = _create_number_field()
	var boolean_field = _create_boolean_field()
	var actions = DebugEntryActions.instantiate()

	actions.save_pressed.connect(_on_action_save_pressed.bind(var_name))
	actions.edit_pressed.connect(_on_action_edit_pressed.bind(var_name))
	actions.cancel_pressed.connect(_on_action_cancel_pressed.bind(var_name))
	actions.delete_pressed.connect(_on_action_delete_pressed.bind(var_name))

	type_field.item_selected.connect(_on_type_item_selected.bind(var_name))

	_var_entries.add_child(name_field)
	_var_entries.add_child(type_field)
	_var_entries.add_child(string_field)
	_var_entries.add_child(number_field)
	_var_entries.add_child(boolean_field)
	_var_entries.add_child(actions)

	_variables[var_name] = {
		"name": name_field,
		"type": type_field,
		"value_string": string_field,
		"value_number": number_field,
		"value_boolean": boolean_field,
		"actions": actions,
		"current_type": Types.BooleanValue,
	}


func _update_variable(var_name: String, var_value):
	var var_fields = _variables[var_name]

	if var_value is String:
		_change_type(var_fields, Types.StringValue)
		var_fields.value_string.text = var_value
	elif var_value is float or var_value is int:
		_change_type(var_fields, Types.NumberValue)
		var_fields.value_number.value = var_value
	elif var_value is bool:
		_change_type(var_fields, Types.BooleanValue)
		var_fields.value_boolean.button_pressed = var_value


func _change_type(var_fields: Dictionary, type: Types):
	if type == var_fields.current_type:
		return
	var_fields.value_boolean.hide()
	var_fields.value_number.hide()
	var_fields.value_string.hide()
	var_fields.current_type = type
	var_fields.type.selected = type
	match type:
		Types.StringValue:
			var_fields.value_string.show()
		Types.BooleanValue:
			var_fields.value_boolean.show()
		Types.NumberValue:
			var_fields.value_number.show()


func _create_name_field(var_name: String) -> LineEdit:
	var field = LineEdit.new()
	field.text = var_name
	field.focus_mode = field.FOCUS_NONE
	field.editable = false
	field.size_flags_horizontal = Container.SIZE_EXPAND_FILL
	return field


func _create_type_field() -> OptionButton:
	var field = OptionButton.new()
	field.add_item("Boolean")
	field.add_item("Number")
	field.add_item("String")
	field.selected = 0
	field.focus_mode = field.FOCUS_NONE
	field.disabled = true
	field.size_flags_horizontal = Container.SIZE_EXPAND_FILL
	return field


func _create_string_field() -> LineEdit:
	var field = LineEdit.new()
	field.editable = false
	field.focus_mode = field.FOCUS_NONE
	field.visible = false
	field.size_flags_horizontal = Container.SIZE_EXPAND_FILL
	return field


func _create_number_field() -> SpinBox:
	var field = SpinBox.new()
	field.editable = false
	field.focus_mode = field.FOCUS_NONE
	field.visible = false
	field.size_flags_horizontal = Container.SIZE_EXPAND_FILL
	return field


func _create_boolean_field() -> CheckBox:
	var field = CheckBox.new()
	field.disabled = true
	field.focus_mode = field.FOCUS_NONE
	field.size_flags_horizontal = Container.SIZE_EXPAND_FILL
	return field


func _on_action_save_pressed(var_name: String):
	if var_name == ADD_VAR_TEMP_NAME:
		var new_name = _handle_var_creation()
		if not new_name:
			return
		var_name = new_name
		_is_adding = false
		_add_var_btn.disabled = false
	_save_fields(var_name)


func _on_action_edit_pressed(var_name: String):
	_set_fields_edit_mode(var_name)


func _on_action_delete_pressed(var_name: String):
	variable_changed.emit(var_name, null)
	_remove_var(var_name)


func _on_action_cancel_pressed(var_name: String):
	if var_name == ADD_VAR_TEMP_NAME:
		_remove_var(var_name)
		_is_adding = false
		_add_var_btn.disabled = false


func _save_fields(var_name: String):
	var value = _get_field_value(var_name)
	variable_changed.emit(var_name, value)
	_set_fields_normal_mode(var_name)


func _get_field_value(var_name: String):
	var fields = _variables[var_name]
	match fields.current_type:
		Types.BooleanValue:
			return fields.value_boolean.button_pressed
		Types.NumberValue:
			return fields.value_number.value
		Types.StringValue:
			return fields.value_string.text


func _set_fields_edit_mode(var_name: String):
	var var_fields = _variables[var_name]
	var_fields.type.focus_mode = var_fields.type.FOCUS_ALL
	var_fields.type.disabled = false

	var_fields.value_boolean.focus_mode = var_fields.value_boolean.FOCUS_ALL
	var_fields.value_boolean.disabled = false

	var_fields.value_string.focus_mode = var_fields.value_string.FOCUS_ALL
	var_fields.value_string.editable = true

	var_fields.value_number.focus_mode = var_fields.value_number.FOCUS_ALL
	var_fields.value_number.editable = true


func _set_fields_normal_mode(var_name: String):
	var var_fields = _variables[var_name]
	var_fields.type.focus_mode = var_fields.type.FOCUS_NONE
	var_fields.type.disabled = true

	var_fields.value_boolean.focus_mode = var_fields.value_boolean.FOCUS_NONE
	var_fields.value_boolean.disabled = true

	var_fields.value_string.focus_mode = var_fields.value_string.FOCUS_NONE
	var_fields.value_string.editable = false

	var_fields.value_number.focus_mode = var_fields.value_number.FOCUS_NONE
	var_fields.value_number.editable = false


func _handle_var_creation():
	var fields = _variables[ADD_VAR_TEMP_NAME]
	var valid_id = RegEx.create_from_string("^[A-z_]+[A-z0-9_]*");
	if valid_id.search(fields.name.text) == null:
		return false
	var new_name = fields.name.text
	_variables[new_name] = fields
	_variables.erase(ADD_VAR_TEMP_NAME)

	fields.name.focus_mode = fields.name.FOCUS_NONE
	fields.name.editable = false

	var actions = fields.actions

	actions.save_pressed.disconnect(_on_action_save_pressed.bind(ADD_VAR_TEMP_NAME))
	actions.edit_pressed.disconnect(_on_action_edit_pressed.bind(ADD_VAR_TEMP_NAME))
	actions.cancel_pressed.disconnect(_on_action_cancel_pressed.bind(ADD_VAR_TEMP_NAME))
	actions.delete_pressed.disconnect(_on_action_delete_pressed.bind(ADD_VAR_TEMP_NAME))
	fields.type.item_selected.disconnect(_on_type_item_selected.bind(ADD_VAR_TEMP_NAME))

	actions.save_pressed.connect(_on_action_save_pressed.bind(new_name))
	actions.edit_pressed.connect(_on_action_edit_pressed.bind(new_name))
	actions.cancel_pressed.connect(_on_action_cancel_pressed.bind(new_name))
	actions.delete_pressed.connect(_on_action_delete_pressed.bind(new_name))
	fields.type.item_selected.connect(_on_type_item_selected.bind(new_name))

	return new_name


func _on_type_item_selected(index: int, var_name: String):
	_change_type(_variables[var_name], index)


func _remove_var(var_name):
	var fields = _variables[var_name]
	fields.name.queue_free()
	fields.type.queue_free()
	fields.value_string.queue_free()
	fields.value_number.queue_free()
	fields.value_boolean.queue_free()
	fields.actions.queue_free()
	_variables.erase(var_name)


func start_add_variable_mode():
	if _is_adding:
		return
	_is_adding = true
	_add_var_btn.disabled = true
	_create_variable_fields(ADD_VAR_TEMP_NAME)
	var name_field = _variables[ADD_VAR_TEMP_NAME].name
	_variables[ADD_VAR_TEMP_NAME].actions.save_mode(true)
	_set_fields_edit_mode(ADD_VAR_TEMP_NAME)
	name_field.focus_mode = name_field.FOCUS_ALL
	name_field.editable = true
	name_field.text = "var_name"


func clear_entries():
	for c in _var_entries.get_children():
		c.queue_free()
	_variables = {}
