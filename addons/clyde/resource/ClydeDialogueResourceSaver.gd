tool
class_name ClydeDialogueResourceSaver extends ResourceFormatSaver

const ClydeResource = preload("./ClydeDialogueResource.gd")

func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["clyde", "res"])
#
#
func recognize(resource: Resource) -> bool:
	resource = resource as ClydeResource
	return resource != null


func _save(path: String, resource: Resource,  flags: int) -> int:
	return ResourceSaver.save(path, resource)
