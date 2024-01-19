@tool
extends VBoxContainer

signal file_selected(file_path: String)

var _edited = []
var _files = {}

@onready
var _items = $ItemList

# TODO sorting
# TODO filter

func add_file(file_path: String):
	if _files.has(file_path):
		return

	var file_name = file_path.get_file()
	_files[file_path] = {
		"file_name": file_name,
		"file": file_path,
		"is_edited": false,
		"index": _items.add_item(file_name, get_theme_icon("Script", "EditorIcons")),
	}
	_items.set_item_metadata(_files[file_path].index, file_path)


func remove_file(file_path: String):
	if not _files.has(file_path):
		return

	_files.erase(file_path)
	reload_list()


func change_file(old_file_path: String, new_file_path: String):
	if not _files.has(old_file_path):
		return
	var file = _files[old_file_path]
	_files[new_file_path] = file
	_files.erase(old_file_path)
	file.file_name = new_file_path.get_file()

	reload_list()


func select_file(file_path):
	if not _files.has(file_path):
		return
	var index = _files[file_path].index
	_items.select(index)


func mark_edited(file_path):
	if not _files.has(file_path):
		add_file(file_path)

	var file = _files[file_path]
	_items.set_item_text(file.index, _edited_name(file.file_name))
	file.is_edited = true


func mark_saved(file_path):
	var file = _files[file_path]
	_items.set_item_text(file.index, file.file_name)
	file.is_edited = false


func reload_list():
	_items.clear()
	for file_path in _files:
		var file = _files[file_path]
		file.index = _items.add_item(
			file.file_name if not file.is_edited else _edited_name(file.file_name),
			get_theme_icon("Script", "EditorIcons")
		)
		_items.set_item_metadata(_files[file_path].index, file_path)


func is_unsaved(file_path: String):
	var file = _files[file_path]
	return file.is_edited


func _edited_name(file_name):
	return "%s(*)" % file_name


func _on_item_list_item_selected(index):
	var path = _items.get_item_metadata(index)
	file_selected.emit(path)


func _on_filter_text_changed(new_text):
	pass # Replace with function body.


func open_file_count() -> int:
	return _files.keys().size()


func get_open_files_paths() -> Array:
	return _files.keys()
