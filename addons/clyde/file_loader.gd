extends Reference

# Custom folder where the interpreter should look for dialogue files
# in case just the name is provided.
# by default, it loads from ProjectSettings dialogue/source_folder
var dialogue_folder = null

## Load dialogue file.[br]
## file_name: path to the dialogue file. I.e 'my_dialogue', 'res://my_dialogue.clyde', res://my_dialogue.json [br]
func load_file(file_name: String) -> Dictionary:
	return _load_file(get_file_path(file_name))


func load_file_in_path(file_path) -> Dictionary:
	return _load_file(file_path)


func _load_file(path) -> Dictionary:
	if path.get_extension() == 'clyde':
		var container = _load_clyde_file(path)
		return container as Dictionary

	var f := File.new()
	f.open(path, File.READ)
	var result := JSON.parse(f.get_as_text())
	f.close()
	if result.error:
		printerr("Failed to parse file: ", f.get_error())
		return {}

	return result.result as Dictionary


func _load_clyde_file(path):
	var data = load(path)
	return data.content


func get_file_path(file_name):
	var p = file_name
	var extension = file_name.get_extension()

	if (not extension):
		p = "%s.clyde" % file_name

	if p.begins_with('./') or p.begins_with('res://'):
		return p

	return _get_source_folder().plus_file(p)


func _get_source_folder():
	var cfg_folder = ProjectSettings.get_setting("dialogue/source_folder") if ProjectSettings.has_setting("dialogue/source_folder") else null
	var folder = dialogue_folder if dialogue_folder else cfg_folder
	# https://github.com/godotengine/godot/issues/56598
	return folder if folder else "res://dialogues/"
