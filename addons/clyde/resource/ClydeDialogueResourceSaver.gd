@tool
class_name ClydeDialogueResourceSaver extends ResourceFormatSaver


const ClydeResource = preload("./ClydeDialogueResource.gd")

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["clyde", "res"])


func _recognize(resource: Resource) -> bool:
	resource = resource as ClydeResource
	return resource != null


func _save(resource: Resource, path: String, flags: int) -> int:
	return ResourceSaver.save(resource, path)
