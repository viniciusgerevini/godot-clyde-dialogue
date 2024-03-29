extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

const SAMPLES_FOLDER = "res://test/dialogue_samples/"

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)


func test_samples():
	var files = []
	var dir = DirAccess.open(SAMPLES_FOLDER)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break

		if file.ends_with(".clyde"):
			files.append(file)

	dir.list_dir_end()

	for file_name in files:
		var result_filename = file_name.replace('.clyde', '.json')
		var source_file = FileAccess.open("%s%s" % [ SAMPLES_FOLDER, file_name ], FileAccess.READ)
		var source = source_file.get_as_text()
		source_file.close()

		var result_file = FileAccess.open("%s%s" % [ SAMPLES_FOLDER, result_filename ], FileAccess.READ)
		var result = result_file.get_as_text()

		var test_json_conv = JSON.new()
		test_json_conv.parse(result)
		expect(parse(source), test_json_conv.get_data())
		pass_test("passed")


func expect(received, expected):
	if typeof(expected) == TYPE_ARRAY:
		_expect_assert(received != null && received.size() == expected.size(),"'%s' is not equal to '%s" % [ received, expected ])
		for index in range(expected.size()):
			expect(received[index], expected[index])
	elif typeof(received) == TYPE_DICTIONARY:
		for key in expected:
			expect(received[key], expected[key])
	else:
		_expect_assert(received == expected,"'%s' is not equal to '%s" % [ received, expected ])


func is_in_array(array, element):
	_expect_assert(array.has(element),'%s is not in array' % element)


func _expect_assert(assertion_result, message):
	if not assertion_result:
		printerr("%s: test failed: %s" % [self.name, message])
		return false
	return true

