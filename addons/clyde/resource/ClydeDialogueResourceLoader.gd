@tool
class_name ClydeDialogueResourceLoader extends ResourceFormatLoader

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
	return ResourceLoader.load(path)
