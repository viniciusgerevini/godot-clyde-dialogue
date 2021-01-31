extends Node2D

var pending = []

func _ready():
	var test_files = _get_test_files()
	for t in test_files:
		var node = Node2D.new()
		node.set_script(load("res://test/%s" % t))
		node.name = t.get_basename()
		node.connect("all_tests_finished", self, "_on_test_finished", [node])
		pending.push_back(node)
		add_child(node)


func _on_test_finished(test):
	print("=== %s [COMPLETED]" % test.name)
	pending.erase(test)
	if pending.size() == 0:
		get_tree().quit()


func _get_test_files():
	var files = []
	var dir = Directory.new()
	dir.open('res://test/')
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break

		if not file.begins_with(".") and file.ends_with("_tests.gd"):
			files.append(file)

	dir.list_dir_end()

	return files
