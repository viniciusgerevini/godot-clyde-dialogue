tool
class_name ClydeDialogueResourceLoader extends ResourceFormatLoader


func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["clyde", "res"])


func get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "clyde":
		return "ClydeDialogueFile"
	return ""


func handles_type(typename: String) -> bool:
	return ["ClydeDialogueFile", "Resource", "TextFile"].has(typename)


func load(path, original_path):
	return ResourceLoader.load(path)
