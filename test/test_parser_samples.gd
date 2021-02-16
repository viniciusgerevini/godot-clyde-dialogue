extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)

func test_samples():
	var files = []
	var dir = Directory.new()
	dir.open('res://dialogues/')
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break

		if file.ends_with(".clyde"):
			files.append(file)

	dir.list_dir_end()

	for file_name in files:
		var result_filename = file_name.replace('.clyde', '.json')
		var source_file = File.new()
		source_file.open("res://dialogues/%s" % file_name, File.READ)
		var source = source_file.get_as_text()
		source_file.close()

		var result_file = File.new()
		result_file.open("res://dialogues/%s" % result_filename, File.READ)
		var result = result_file.get_as_text()

		expect(parse(source), JSON.parse(result).get_result())
		pass_test("passed")

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
		printerr("%s: test failed: %s" % [self.name, message])
		return false
	return true

