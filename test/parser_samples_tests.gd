extends './test.gd'

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)

func _test_samples():
	var files = []
	var dir = Directory.new()
	dir.open('res://sample/')
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
		source_file.open("res://sample/%s" % file_name, File.READ)
		var source = source_file.get_as_text()
		source_file.close()

		var result_file = File.new()
		result_file.open("res://sample/%s" % result_filename, File.READ)
		var result = result_file.get_as_text()

		expect(parse(source), JSON.parse(result).get_result())

