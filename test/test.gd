extends Node2D

signal all_tests_finished

var pending_events = []
var pending_tests = []


func _ready():
	_execute()

func _process(_delta):
	if (pending_tests.size() == 0 and pending_events.size() == 0):
		emit_signal("all_tests_finished")


func add_pending_event(event):
	pending_events.push_back(event)


func _execute():
	for method in self.get_method_list():
		if (method.name.begins_with('_test_')):
			print("%s: %s" % [self.name, method.name])
			pending_tests.push_back(method.name)
			var res = self.call(method.name)
			if not res:
				pending_tests.remove(method.name)


func compare_content(result, expected):
	if not result:
		assert(result == expected, 'result is undefined. Expected: %s' % expected)
		return

	assert(result.get("type") == expected.get("type") , 'line type does not match received: %s expected: %s' % [result.get("type") , expected.get("type")])

	if result.type == 'line':
		compare_line(result, expected)
	else:
		compare_options(result, expected)

func compare_line(result, expected):
	assert(result.get("text")  == expected.get("text"), 'text does not match received: %s expected: %s' % [result.get("text"), expected.get("text")])
	assert(result.get("speaker")  == expected.get("speaker"), 'line speaker does not match received: %s expected: %s' % [result.get("speaker"), expected.get("speaker")])
	assert(result.get("id")  == expected.get("id"), 'line id does not match received: %s expected: %s' % [result.get("id"), expected.get("id")])


func compare_options(result, expected):
	assert(result.get("name")  == expected.get("name"), 'name does not match received: %s expected: %s' % [result.get("name"), expected.get("name")])
	assert(result.get("speaker")  == expected.get("speaker"), 'line speaker does not match received: %s expected: %s' % [result.get("speaker"), expected.get("speaker")])
	assert(result.get("id")  == expected.get("id"), 'line id does not match received: %s expected: %s' % [result.get("id"), expected.get("id")])
	assert(result.options.size()  == expected.options.size(), 'number of options does not match: %s expected: %s' % [result.options.size(), expected.options.size()])
	for index in range(result.options.size()):
		assert(result.options[index].label  == expected.options[index].label, 'option label does not match: %s expected: %s' % [result.options[index].label, expected.options[index].label])
		assert(result.options[index].get("speaker")  == expected.options[index].get("speaker"), 'line speaker does not match received: %s expected: %s' % [result.options[index].get("speaker"), expected.options[index].get("speaker")])
		assert(result.options[index].get("id")  == expected.options[index].get("id"), 'line id does not match received: %s expected: %s' % [result.options[index].get("id"), expected.options[index].get("id")])


func compare_var(received, expected):
	assert(received == expected, "'%s' is not equal to '%s" % [ received, expected ])


func is_in_array(array, element):
	assert(array.has(element), '%s is not in array' % element)
