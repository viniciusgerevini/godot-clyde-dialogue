extends Node2D

signal all_tests_finished(passed)

var pending_events = []
var pending_tests = []
var result = true

func _ready():
	_execute()

func _process(_delta):
	if (pending_tests.size() == 0 and pending_events.size() == 0):
		emit_signal("all_tests_finished", result)


func add_pending_event(event):
	pending_events.push_back(event)


func _execute():
	var _number_of_tests = 0
	for method in self.get_method_list():
		if (method.name.begins_with('_test_')):
			_number_of_tests += 1
#			print("%s: %s" % [self.name, method.name])
			pending_tests.push_back(method.name)
			var res = self.call(method.name)
			if not res:
				pending_tests.remove(method.name)
	print("%s: %s tests" % [self.name, _number_of_tests])


func compare_content(received, expected):
	if not received:
		expect_assert(received == expected, 'result is undefined. Expected: %s' % expected)
		return

	expect_assert(received.get("type") == expected.get("type") , 'line type does not match received: %s expected: %s' % [received.get("type") , expected.get("type")])

	if received.type == 'line':
		compare_line(received, expected)
	else:
		compare_options(received, expected)

func compare_line(received, expected):
	expect_assert(received.get("text")  == expected.get("text"), 'text does not match received: %s expected: %s' % [received.get("text"), expected.get("text")])
	expect_assert(received.get("speaker")  == expected.get("speaker"), 'line speaker does not match received: %s expected: %s' % [received.get("speaker"), expected.get("speaker")])
	expect_assert(received.get("id")  == expected.get("id"), 'line id does not match received: %s expected: %s' % [received.get("id"), expected.get("id")])


func compare_options(received, expected):
	expect_assert(received.get("name")  == expected.get("name"), 'name does not match received: %s expected: %s' % [received.get("name"), expected.get("name")])
	expect_assert(received.get("speaker")  == expected.get("speaker"), 'line speaker does not match received: %s expected: %s' % [received.get("speaker"), expected.get("speaker")])
	expect_assert(received.get("id")  == expected.get("id"), 'line id does not match received: %s expected: %s' % [received.get("id"), expected.get("id")])
	expect_assert(received.options.size()  == expected.options.size(), 'number of options does not match: %s expected: %s' % [received.options.size(), expected.options.size()])
	for index in range(received.options.size()):
		expect_assert(received.options[index].label  == expected.options[index].label, 'option label does not match: %s expected: %s' % [received.options[index].label, expected.options[index].label])
		expect_assert(received.options[index].get("speaker")  == expected.options[index].get("speaker"), 'line speaker does not match received: %s expected: %s' % [received.options[index].get("speaker"), expected.options[index].get("speaker")])
		expect_assert(received.options[index].get("id")  == expected.options[index].get("id"), 'line id does not match received: %s expected: %s' % [received.options[index].get("id"), expected.options[index].get("id")])


func expect(received, expected):
	if typeof(expected) == TYPE_ARRAY:
		expect_assert(received != null && received.size() == expected.size(), "'%s' is not equal to '%s" % [ received, expected ])
		for index in range(expected.size()):
			expect(received[index], expected[index])
	elif typeof(received) == TYPE_DICTIONARY:
		for key in expected:
			expect(received[key], expected[key])
	else:
		expect_assert(received == expected, "'%s' is not equal to '%s" % [ received, expected ])


func is_in_array(array, element):
	expect_assert(array.has(element), '%s is not in array' % element)


func expect_assert(assertion_result, message):
	if not assertion_result:
		result = false
		printerr("%s: test failed: %s" % [self.name, message])
		return false
	return true
