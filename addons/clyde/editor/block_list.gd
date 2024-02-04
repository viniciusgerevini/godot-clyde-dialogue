@tool
extends VBoxContainer

signal block_selected(line: int, column: int)

const InterfaceText = preload("./config/interface_text.gd")

@onready var _file_name = $HBoxContainer/file_name
@onready var _filter = $filter
@onready var _sort_button = $HBoxContainer/sort_button
@onready var _items = $ItemList

var _blocks = {}
var _block_names = []
var _block_names_alphabetical = []


func _ready():
	_filter.placeholder_text = InterfaceText.get_string(InterfaceText.KEY_FILTER_BLOCKS)
	_filter.right_icon = get_theme_icon("Search", "EditorIcons")
	_sort_button.icon = get_theme_icon("Sort", "EditorIcons")


func load_file(filepath: String, blocks: Array):
	_blocks = {}
	_block_names = []
	_block_names_alphabetical = []
	_file_name.text = filepath.get_file() if filepath != "" else "New dialogue"
	_file_name.tooltip_text = filepath

	for block in blocks:
		_block_names.push_back(block.name)
		_block_names_alphabetical.push_back(block.name)
		_blocks[block.name] = block

	_block_names_alphabetical.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)

	_load_list()


func _load_list():
	var filter_text: String = _filter.text.strip_edges()
	_items.clear()
	for item in _get_items():
		if filter_text.is_empty() or item.contains(filter_text):
			_items.add_item(item)


func _on_sort_button_toggled(_toggled_on):
	_load_list()


func _on_item_list_item_selected(index):
	var item = _items.get_item_text(index)
	var block = _blocks[item]

	block_selected.emit(block.meta.line, block.meta.column)


func _get_items():
	return _block_names_alphabetical if _sort_button.button_pressed else _block_names


func _on_filter_text_changed(_new_text):
	_load_list()
