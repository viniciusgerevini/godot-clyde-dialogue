@tool
extends HBoxContainer

const Shortcuts = preload("./config/shortcuts.gd")
const InterfaceText = preload("./config/interface_text.gd")

signal new_file_triggered
signal open_file_triggered
signal save_file_triggered
signal save_as_triggered
signal save_all_triggered
signal reload_from_disk
signal show_in_filesystem_triggered
signal close_file_triggered
signal close_all_triggered
signal close_other_triggered

signal toggle_file_list_triggered
signal toggle_player_triggered
signal toggle_player_sync

signal execute_dialogue

@onready var _file_menu: PopupMenu = $file_menu.get_popup()
@onready var _tool_menu: PopupMenu = $tool_menu.get_popup()

@onready var _execute_dialogue := $right_icons/MarginContainer/execute_dialogue

enum FileMenu {
	NEW_FILE = 100,
	OPEN_FILE = 200,
	SAVE_FILE = 300,
	SAVE_AS = 400,
	SAVE_ALL = 500,
	RELOAD_FROM_DISK = 600,
	SHOW_IN_FILESYSTEM = 700,
	CLOSE = 800,
	CLOSE_ALL = 900,
	CLOSE_OTHERS = 1000,
}

enum ToolMenu {
	TOGGLE_FILE_LIST = 100,
	TOGGLE_PLAYER = 200,
	EXECUTE_DIALOGUE = 300,
	TOGGLE_PLAYER_SYNC = 400,
}

var _disabled_when_no_file = [
	FileMenu.SAVE_FILE,
	FileMenu.SAVE_AS,
	FileMenu.SAVE_ALL,
	FileMenu.RELOAD_FROM_DISK,
	FileMenu.SHOW_IN_FILESYSTEM,
	FileMenu.CLOSE,
	FileMenu.CLOSE_ALL,
	FileMenu.CLOSE_OTHERS,
]

var _tool_disabled_when_no_file = [
	ToolMenu.EXECUTE_DIALOGUE,
]

var _file_menu_triggers = {
	FileMenu.OPEN_FILE: open_file_triggered,
	FileMenu.NEW_FILE: new_file_triggered,
	FileMenu.SAVE_FILE: save_file_triggered,
	FileMenu.SAVE_AS: save_as_triggered,
	FileMenu.SAVE_ALL: save_all_triggered,
	FileMenu.RELOAD_FROM_DISK: reload_from_disk,
	FileMenu.SHOW_IN_FILESYSTEM: show_in_filesystem_triggered,
	FileMenu.CLOSE: close_file_triggered,
	FileMenu.CLOSE_ALL: close_all_triggered,
	FileMenu.CLOSE_OTHERS: close_other_triggered,
}

var _tool_menu_triggers = {
	ToolMenu.TOGGLE_FILE_LIST: toggle_file_list_triggered,
	ToolMenu.TOGGLE_PLAYER: toggle_player_triggered,
	ToolMenu.EXECUTE_DIALOGUE: execute_dialogue,
	ToolMenu.TOGGLE_PLAYER_SYNC: toggle_player_sync,
}


func _ready():
	var shortcuts = Shortcuts.new()
	_initialize_menus(shortcuts)
	_initialize_right_icons(shortcuts)
	_toggle_entries_that_require_files(false)


func _initialize_menus(shortcuts):
	_initilize_file_menu(shortcuts)
	_initilize_tool_menu(shortcuts)
	_initilize_help_menu(shortcuts)


func _initilize_file_menu(shortcuts):
	$file_menu.text = InterfaceText.get_string(InterfaceText.KEY_MENU_FILE)
	_file_menu.clear()
	_file_menu.id_pressed.connect(_on_file_menu_item_selected)

	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_NEW_FILE, FileMenu.NEW_FILE, shortcuts, Shortcuts.CMD_NEW_FILE)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_OPEN_FILE, FileMenu.OPEN_FILE, shortcuts, Shortcuts.CMD_OPEN_FILE)

	_file_menu.add_separator()

	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_SAVE_FILE, FileMenu.SAVE_FILE, shortcuts, Shortcuts.CMD_SAVE_FILE)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_SAVE_AS, FileMenu.SAVE_AS, shortcuts)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_SAVE_ALL, FileMenu.SAVE_ALL, shortcuts, Shortcuts.CMD_SAVE_ALL)

	_file_menu.add_separator()

	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_RELOAD_FROM_DISK, FileMenu.RELOAD_FROM_DISK, shortcuts, Shortcuts.CMD_RELOAD_FILE)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_SHOW_IN_FILESYSTEM, FileMenu.SHOW_IN_FILESYSTEM)

	_file_menu.add_separator()

	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_CLOSE, FileMenu.CLOSE, shortcuts, Shortcuts.CMD_CLOSE_FILE)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_CLOSE_ALL, FileMenu.CLOSE_ALL)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_CLOSE_OTHER, FileMenu.CLOSE_OTHERS)


func _initilize_tool_menu(shortcuts: Shortcuts):
	$tool_menu.text = InterfaceText.get_string(InterfaceText.KEY_MENU_TOOL)
	_tool_menu.clear()
	_tool_menu.hide_on_checkable_item_selection = false
	_tool_menu.id_pressed.connect(_on_tool_menu_item_selected)

	_add_separator(_tool_menu, InterfaceText.KEY_TOOL_MENU_EDITOR_SECTION)

	_add_check_item(
		_tool_menu,
		InterfaceText.KEY_TOOL_MENU_SHOW_LISTS,
		ToolMenu.TOGGLE_FILE_LIST,
		true,
		shortcuts,
		Shortcuts.CMD_LISTS_TOGGLE
	)

	_add_check_item(
		_tool_menu,
		InterfaceText.KEY_TOOL_MENU_PLAYER_SYNC,
		ToolMenu.TOGGLE_PLAYER_SYNC,
		true
	)

	# player section

	_add_separator(_tool_menu, InterfaceText.KEY_TOOL_MENU_PLAYER_SECTION)

	_add_item(_tool_menu, InterfaceText.KEY_EXECUTE_DIALOGUE, ToolMenu.EXECUTE_DIALOGUE, shortcuts, Shortcuts.CMD_EDITOR_EXECUTE_DIALOGUE)

	_add_check_item(
		_tool_menu,
		InterfaceText.KEY_TOOL_MENU_SHOW_PLAYER,
		ToolMenu.TOGGLE_PLAYER,
		false,
		shortcuts,
		Shortcuts.CMD_PLAYER_TOGGLE
	)

	# TODO dialogue section
	# generate ids
	# translation: submenu
	# generate csv from file (open save dialogue with <filename>.csv pre-filled


func _initilize_help_menu(_shortcuts):
	$help_menu.text = InterfaceText.get_string(InterfaceText.KEY_MENU_HELP)
	# TODO docs
	# TODO report issue
	# TODO about (versions, license)
	# TODO load demo dialogue
	# TODO editor commands

func _on_file_menu_item_selected(id: int):
	if _file_menu_triggers.has(id):
		_file_menu_triggers[id].emit()


func _on_tool_menu_item_selected(id: int):
	if _tool_menu_triggers.has(id):
		_tool_menu_triggers[id].emit()


func _initialize_right_icons(_shortcuts):
	_execute_dialogue.icon = get_theme_icon("Play", "EditorIcons")
	_execute_dialogue.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_EXECUTE_DIALOGUE)


func refresh(open_file_count: int):
	if open_file_count > 0:
		_toggle_entries_that_require_files(true)
		_execute_dialogue.disabled = false
		_execute_dialogue.focus_mode = _execute_dialogue.FOCUS_ALL
	else:
		_toggle_entries_that_require_files(false)
		_execute_dialogue.disabled = true
		_execute_dialogue.focus_mode = _execute_dialogue.FOCUS_NONE


func _toggle_entries_that_require_files(enabled: bool):
	for i in _disabled_when_no_file:
		_file_menu.set_item_disabled(_file_menu.get_item_index(i), not enabled)

	for i in _tool_disabled_when_no_file:
		_tool_menu.set_item_disabled(_file_menu.get_item_index(i), not enabled)


func set_lists_visibility(is_visible: bool):
	var toggle_index = _tool_menu.get_item_index(ToolMenu.TOGGLE_FILE_LIST)
	_tool_menu.set_item_checked(toggle_index, is_visible)


func set_player_visibility(is_visible: bool):
	var toggle_index = _tool_menu.get_item_index(ToolMenu.TOGGLE_PLAYER)
	_tool_menu.set_item_checked(toggle_index, is_visible)


func set_editor_sync(should_sync: bool):
	var toggle_index = _tool_menu.get_item_index(ToolMenu.TOGGLE_PLAYER_SYNC)
	_tool_menu.set_item_checked(toggle_index, should_sync)


func _on_execute_dialogue_pressed():
	execute_dialogue.emit()


func _add_separator(menu: PopupMenu, text_key: String):
	menu.add_separator(InterfaceText.get_string(text_key))


func _add_check_item(menu: PopupMenu, text_key: String, id: int, default_value: bool, shortcuts: Shortcuts = null, command = null):
	menu.add_check_item(InterfaceText.get_string(text_key), id)
	var index = menu.get_item_index(id)
	menu.set_item_checked(index, default_value)
	if command != null:
		menu.set_item_shortcut(index, shortcuts.get_shortcut_for_command(command))


func _add_item(menu: PopupMenu, text_key: String, id: int, shortcuts: Shortcuts = null, command = null):
	menu.add_item(InterfaceText.get_string(text_key), id)
	if command != null:
		menu.set_item_shortcut(menu.get_item_index(id), shortcuts.get_shortcut_for_command(command))
