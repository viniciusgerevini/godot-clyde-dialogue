@tool
class_name ClydeDialogueResourceLoader extends ResourceFormatLoader
const Parser = preload("../parser/Parser.gd")

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["clyde", "res"])


func _get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "clyde":
		return "ClydeDialogueFile"
	return ""


func _handles_type(type: StringName) -> bool:
	return ["ClydeDialogueFile", "Resource", "TextFile"].has(type)


func _load(path, original_path, use_sub_threads, cache_mode):
	if !path.begins_with("res://"):
		var file = FileAccess.open(path, FileAccess.READ)
		var clyde = file.get_as_text()
		var container = ClydeDialogueFile.new()
		var parser = Parser.new()
		container.content = parser.parse(clyde)
		return container
	return ResourceLoader.load(path)
