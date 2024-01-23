@tool
extends VBoxContainer

signal file_selected(file_path: String)
signal save_file_triggered
signal save_as_triggered
signal reload_from_disk
signal show_in_filesystem_triggered
signal close_file_triggered
signal close_all_triggered
signal close_other_triggered
signal copy_current_path_triggered

const InterfaceText = preload("./config/interface_text.gd")
const Shortcuts = preload("./config/shortcuts.gd")

enum Menu {
	SAVE_FILE = 300,
	SAVE_AS = 400,
	RELOAD_FROM_DISK = 600,
	COPY_PATH = 601,
	SHOW_IN_FILESYSTEM = 700,
	CLOSE = 800,
	CLOSE_ALL = 900,
	CLOSE_OTHERS = 1000,
	SORT = 1100,
}

var _edited = []
var _files = {}
var _last_selection

@onready var _items = $ItemList
@onready var _menu = $Menu
@onready var _filter = $filter

func _ready():
	_initilize_menu()
	_filter.placeholder_text = InterfaceText.get_string(InterfaceText.KEY_FILTER_FILES)
	_filter.right_icon = get_theme_icon("Search", "EditorIcons")


func add_file(file_path: String):
	if _files.has(file_path):
		return

	var file_name = file_path.get_file()
	_files[file_path] = {
		"file_name": file_name,
		"file": file_path,
		"is_edited": false,
		"index": _items.add_item(file_name, get_theme_icon("Script", "EditorIcons")),
		"is_visible": true,
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
	_last_selection = file_path


func mark_edited(file_path):
	if not _files.has(file_path):
		add_file(file_path)

	var file = _files[file_path]
	if file.is_visible:
		_items.set_item_text(file.index, _edited_name(file.file_name))
	file.is_edited = true


func mark_saved(file_path):
	var file = _files[file_path]
	if file.is_visible:
		_items.set_item_text(file.index, file.file_name)
	file.is_edited = false


func reload_list():
	var filter_text: String = _filter.text.strip_edges()

	_items.clear()
	for file_path in _files:
		var file = _files[file_path]
		if filter_text.is_empty() or file.file_name.contains(filter_text):
			file.is_visible = true
			file.index = _items.add_item(
				file.file_name if not file.is_edited else _edited_name(file.file_name),
				get_theme_icon("Script", "EditorIcons")
			)
			_items.set_item_metadata(_files[file_path].index, file_path)
		else:
			file.is_visible = false


func is_unsaved(file_path: String):
	var file = _files[file_path]
	return file.is_edited


func _edited_name(file_name):
	return "%s(*)" % file_name


func _on_item_list_item_selected(index):
	var path = _items.get_item_metadata(index)
	file_selected.emit(path)
	_last_selection = path


func open_file_count() -> int:
	return _files.keys().size()


func get_open_files_paths() -> Array:
	return _files.keys()


func _initilize_menu():
	var shortcuts = Shortcuts.new()
	_menu.clear()
	_menu.id_pressed.connect(_on_menu_item_selected)

	_add_item(_menu, InterfaceText.KEY_FILE_MENU_SAVE_FILE, Menu.SAVE_FILE, shortcuts, Shortcuts.CMD_SAVE_FILE)
	_add_item(_menu, InterfaceText.KEY_FILE_MENU_SAVE_AS, Menu.SAVE_AS, shortcuts)
	_add_item(_menu, InterfaceText.KEY_FILE_MENU_CLOSE, Menu.CLOSE, shortcuts, Shortcuts.CMD_CLOSE_FILE)
	_add_item(_menu, InterfaceText.KEY_FILE_MENU_CLOSE_ALL, Menu.CLOSE_ALL)
	_add_item(_menu, InterfaceText.KEY_FILE_MENU_CLOSE_OTHER, Menu.CLOSE_OTHERS)

	_menu.add_separator()

	_add_item(_menu, InterfaceText.KEY_FILE_MENU_RELOAD_FROM_DISK, Menu.RELOAD_FROM_DISK, shortcuts, Shortcuts.CMD_RELOAD_FILE)
	_add_item(_menu, InterfaceText.KEY_COPY_FILE_PATH, Menu.COPY_PATH)
	_add_item(_menu, InterfaceText.KEY_FILE_MENU_SHOW_IN_FILESYSTEM, Menu.SHOW_IN_FILESYSTEM)

	_menu.add_separator()

	_add_item(_menu, InterfaceText.KEY_SORT, Menu.SORT)


func _on_menu_item_selected(id: int):
	match id:
		Menu.SAVE_FILE:
			save_file_triggered.emit()
		Menu.SAVE_AS:
			save_as_triggered.emit()
		Menu.RELOAD_FROM_DISK:
			reload_from_disk.emit()
		Menu.COPY_PATH:
			copy_current_path_triggered.emit()
		Menu.SHOW_IN_FILESYSTEM:
			show_in_filesystem_triggered.emit()
		Menu.CLOSE:
			close_file_triggered.emit()
		Menu.CLOSE_ALL:
			close_all_triggered.emit()
		Menu.CLOSE_OTHERS:
			close_other_triggered.emit()
		Menu.SORT:
			_sort_list()


func _add_item(menu: PopupMenu, text_key: String, id: int, shortcuts: Shortcuts = null, command = null):
	menu.add_item(InterfaceText.get_string(text_key), id)
	if command != null:
		menu.set_item_shortcut(menu.get_item_index(id), shortcuts.get_shortcut_for_command(command))


func _on_item_list_item_clicked(index, _at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_menu.position = get_viewport().get_mouse_position()
		_menu.popup()


func _on_filter_text_changed(new_text):
	reload_list()
	_focus_on_last_selected()


func _focus_on_last_selected():
	if _last_selection == null or not _files.has(_last_selection):
		return
	var file = _files[_last_selection]
	if file.is_visible:
		_items.select(file.index)


func _sort_list():
	_items.sort_items_by_text()
	for i in range(_items.item_count):
		var path = _items.get_item_metadata(i)
		_files[path].index = i
