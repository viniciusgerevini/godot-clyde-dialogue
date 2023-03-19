extends RefCounted

signal variable_changed(name, value, previous_value)

const SPECIAL_VARIABLE_NAMES = [ 'OPTIONS_COUNT' ];

var _mem = {
	"access": {},
	"variables": {},
	"internal": {}
}

func set_as_accessed(id):
	_mem.access[str(id)] = true


func was_already_accessed(id):
	return _mem.access.has(str(id))


func get_variable(id, default_value = null):
	if SPECIAL_VARIABLE_NAMES.has(id):
		return get_internal_variable(id, default_value);

	var value = _mem.variables.get(id);
	if (value == null):
		return default_value;
	return value;


func set_variable(id, value):
	self.emit_signal("variable_changed", id, value, _mem.variables.get(id))
	_mem.variables[id] = value
	return value


func set_internal_variable(id, value):
	_mem.internal[str(id)] = value
	return value


func get_internal_variable(id, default_value):
	var value = _mem.internal.get(str(id));
	if value == null:
		return default_value;
	return value


func get_all():
	return _mem


func load_data(data):
	_mem = data


func clear():
	_mem = {
		"access": {},
		"variables": {},
		"internal": {}
	}
