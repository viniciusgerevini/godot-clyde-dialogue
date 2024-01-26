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
	return ["ClydeDialogueFile", "PackedDataContainer", "TextFile"].has(type)


func _load(path, original_path, use_sub_threads, cache_mode):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file.is_open():
		return file.get_open_error()

	var resource = ClydeDialogueFile.new()
	resource.__data__ = file.get_as_text().to_utf8_buffer()
	return resource
