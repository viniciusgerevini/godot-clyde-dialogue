@tool
class_name ClydeDialogueResourceSaver extends ResourceFormatSaver


const ClydeResource = preload("./ClydeDialogueResource.gd")

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["clyde", "res"])


func _recognize(resource: Resource) -> bool:
	resource = resource as ClydeResource
	return resource != null


func _save(resource: Resource, path: String, flags: int) -> int:
	var file = FileAccess.open(path, FileAccess.WRITE)

	if not file.is_open():
		return file.get_open_error()

	file.store_string(resource.get("__data__").get_string_from_utf8());
	return OK
