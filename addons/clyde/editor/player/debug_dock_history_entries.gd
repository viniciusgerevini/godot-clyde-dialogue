@tool
extends RefCounted

const InterfaceText = preload("../config/interface_text.gd")

var _event_entries: GridContainer


func _init(event_entries: GridContainer) -> void:
	_event_entries = event_entries


func record_event(event_name: String, parameters: Array):
	_add_event_record(event_name, parameters)


func clear_event_history():
	for c in _event_entries.get_children():
		c.queue_free()
	_create_event_history_header()


func _create_event_history_header():
	var time = Label.new()
	time.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_TIME)
	time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var type = Label.new()
	type.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_TYPE)
	type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name = Label.new()
	name.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_NAME)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val = Label.new()
	val.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_VALUE)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var old_val = Label.new()
	old_val.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_PREVIOUS_VALUE)
	old_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_entries.add_child(time)
	_event_entries.add_child(type)
	_event_entries.add_child(name)
	_event_entries.add_child(val)
	_event_entries.add_child(old_val)
	_add_separator()


func _add_event_record(event_name: String, parameters: Array):
	var type = Label.new()
	type.text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_EVENT_LABEL)
	var name = Label.new()
	name.text = event_name
	var val = Label.new()
	val.text = str(parameters)
	_event_entries.add_child(_time_field())
	_event_entries.add_child(type)
	_event_entries.add_child(name)
	_event_entries.add_child(val)
	_event_entries.add_child(Label.new()) # old value stub
	_add_separator()


func add_variable_record(var_name: String, value, old_value, label = InterfaceText.KEY_DEBUG_VARIABLE_LABEL):
	var type = Label.new()
	type.text = InterfaceText.get_string(label)
	var name = Label.new()
	name.text = var_name
	var val = Label.new()
	val.text = str(value)
	var old_val = Label.new()
	old_val.text = str(old_value)

	_event_entries.add_child(_time_field())
	_event_entries.add_child(type)
	_event_entries.add_child(name)
	_event_entries.add_child(val)
	_event_entries.add_child(old_val)
	_add_separator()


func _add_separator():
	_event_entries.add_child(HSeparator.new())
	_event_entries.add_child(HSeparator.new())
	_event_entries.add_child(HSeparator.new())
	_event_entries.add_child(HSeparator.new())
	_event_entries.add_child(HSeparator.new())


func _time_field():
	var label = Label.new()
	label.text = Time.get_datetime_string_from_system(false, true)
	return label
