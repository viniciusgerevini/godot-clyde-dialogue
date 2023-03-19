extends RefCounted

const SPECIAL_VARIABLE_NAMES = [ 'OPTIONS_COUNT' ];

var _mem

func init(mem):
	_mem = mem


func handle_assignment(assignment):
	var variable = assignment.variable;
	var source = assignment.value;
	var value = _get_node_value(source);

	return _handle_assignment_operation(assignment, variable.name, value)


func _handle_assignment_operation(assignment, var_name, value):
	match assignment.operation:
		"assign":
			return _mem.set_variable(var_name, value)
		"assign_sum":
			return _mem.set_variable(var_name, _mem.get_variable(var_name) + value)
		"assign_sub":
			return _mem.set_variable(var_name, _mem.get_variable(var_name) - value)
		"assign_mult":
			return _mem.set_variable(var_name, _mem.get_variable(var_name) * value)
		"assign_div":
			return _mem.set_variable(var_name, _mem.get_variable(var_name) / value)
		"assign_pow":
			return _mem.set_variable(var_name, pow(_mem.get_variable(var_name), value))
		"assign_mod":
			return _mem.set_variable(var_name, _mem.get_variable(var_name) % value)
		_:
			printerr("Unknown operation %s" % assignment.operation)


func _get_node_value(node):
	match node.type:
		"literal":
			return node.value
		"variable":
			return _mem.get_variable(node.name)
		"assignment":
			return handle_assignment(node)
		"expression":
			return check_expression(node)
		"null":
			return null
	printerr("Unknown node in expression %s" % node.type)


func check_condition(condition):
	match condition.type:
		"expression":
			return check_expression(condition)
		"variable":
			return _mem.get_variable(condition.name)

	printerr("Unknown condition type %s" % condition.type)


func check_expression(node):
	match node.name:
		"equal":
			return _get_node_value(node.elements[0]) == _get_node_value(node.elements[1])
		"not_equal":
			return _get_node_value(node.elements[0]) != _get_node_value(node.elements[1])
		"greater_than":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return false
			return a > b
		"greater_or_equal":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return false
			return a >= b
		"less_than":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return false
			return a < b
		"less_or_equal":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return false
			return a <= b
		"and":
			return check_condition(node.elements[0]) && check_condition(node.elements[1])
		"or":
			return check_condition(node.elements[0]) || check_condition(node.elements[1])
		"not":
			return not check_condition(node.elements[0])
		"mult":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return null
			return a * b
		"div":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return null
			return a / b
		"sub":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return null
			return a - b
		"add":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return null
			return a + b
		"pow":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return null
			return pow(a, b)
		"mod":
			var a = _get_node_value(node.elements[0])
			var b = _get_node_value(node.elements[1])
			if (a == null || b == null):
				return null
			return a % b

	printerr("Unknown expression %s" % node.type)
