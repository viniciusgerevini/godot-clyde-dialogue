extends RefCounted

signal variable_changed(name, value, previous_value)
signal external_variable_changed(name, value, previous_value)

const SPECIAL_VARIABLE_NAMES = [ 'OPTIONS_COUNT' ];

var _mem = {
	"access": {},
	"variables": {},
	"internal": {},
	"e_variables": {},
}

var _external_variable_prefix = "@"

func set_as_accessed(id):
	_mem.access[str(id)] = true


func was_already_accessed(id):
	return _mem.access.has(str(id))


func set_variable(id: String, value: Variant) -> Variant:
	if id.begins_with(_external_variable_prefix):
		return set_external_variable(id, value)

	variable_changed.emit(id, value, _mem.variables.get(id))
	_mem.variables[id] = value
	return value


func get_variable(id, default_value = null):
	if SPECIAL_VARIABLE_NAMES.has(id):
		return get_internal_variable(id, default_value);

	if id.begins_with(_external_variable_prefix):
		return get_external_variable(id, default_value)

	var value = _mem.variables.get(id);
	if (value == null):
		return default_value;
	return value;


func set_internal_variable(id, value):
	_mem.internal[str(id)] = value
	return value


func get_internal_variable(id: String, default_value):
	var value = _mem.internal.get(str(id));
	if value == null:
		return default_value;
	return value


func set_external_variable(id: String, value: Variant):
	var sanitized_id = id.replace(_external_variable_prefix, "")
	var old_var = _mem.e_variables.get(sanitized_id)
	external_variable_changed.emit(sanitized_id, value, old_var)
	_mem.e_variables[sanitized_id] = value
	return value


func get_external_variable(id: String, default_value = null):
	var sanitized_id = str(id).replace(_external_variable_prefix, "")
	var value = _mem.e_variables.get(sanitized_id)
	if value == null:
		return default_value;
	return value


func get_all() -> Dictionary:
	return {
		"access": _mem.access,
		"variables": _mem.variables,
		"internal": _mem.internal,
	}


func load_data(data: Dictionary) -> void:
	_mem = data
	_mem["e_variables"] = {}


func clear() -> void:
	_mem = {
		"access": {},
		"variables": {},
		"internal": {},
		"e_variables": {},
	}
