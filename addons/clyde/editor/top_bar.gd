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
signal toggle_follow_execution

signal execute_dialogue

signal recent_file_triggered(file_path)
signal clear_recent_files_triggered()

signal generate_ids_triggered
signal create_csv_triggered

signal open_online_docs_triggered
signal report_issue_triggered

signal dock_button_pressed

@onready var _file_menu: PopupMenu = $file_menu.get_popup()
@onready var _tool_menu: PopupMenu = $tool_menu.get_popup()
@onready var _recents_submenu: PopupMenu = _create_recents_submenu()
@onready var _help_menu: PopupMenu = $help_menu.get_popup()

@onready var _execute_dialogue := $right_icons/MarginContainer/execute_dialogue
@onready var _dock_button := $right_icons/FloatContainer/dock_button

enum FileMenu {
	NEW_FILE = 100,
	OPEN_FILE = 200,
	OPEN_RECENT = 201,
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
	FOLLOW_EXECUTING_LINE = 201,
	EXECUTE_DIALOGUE = 300,
	TOGGLE_PLAYER_SYNC = 400,
	CREATE_CSV = 500,
	GENERATE_IDS = 600,
}

enum RecentSubMenu {
	CLEAR_RECENTS = 100,
}

enum HelpMenu {
	ONLINE_DOCS = 100,
	REPORT_ISSUE = 200,
	VERSION = 300,
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
	ToolMenu.CREATE_CSV,
	ToolMenu.GENERATE_IDS,
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
	ToolMenu.FOLLOW_EXECUTING_LINE: toggle_follow_execution,
	ToolMenu.EXECUTE_DIALOGUE: execute_dialogue,
	ToolMenu.TOGGLE_PLAYER_SYNC: toggle_player_sync,
	ToolMenu.CREATE_CSV: create_csv_triggered,
	ToolMenu.GENERATE_IDS: generate_ids_triggered,
}

var _help_menu_triggers = {
	HelpMenu.ONLINE_DOCS: open_online_docs_triggered,
	HelpMenu.REPORT_ISSUE: report_issue_triggered,
}

var _recent_files_paths = []

func _ready():
	var shortcuts = Shortcuts.new()
	_initialize_menus(shortcuts)
	_initialize_right_icons(shortcuts)
	_toggle_entries_that_require_files(false)


func _initialize_menus(shortcuts):
	_initilize_file_menu(shortcuts)
	_initilize_tool_menu(shortcuts)
	_initilize_help_menu(shortcuts)
	_initialize_recents_submenu()


func _initilize_file_menu(shortcuts):
	$file_menu.text = InterfaceText.get_string(InterfaceText.KEY_MENU_FILE)
	_file_menu.clear()
	_file_menu.id_pressed.connect(_on_file_menu_item_selected)

	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_NEW_FILE, FileMenu.NEW_FILE, shortcuts, Shortcuts.CMD_NEW_FILE)
	_add_item(_file_menu, InterfaceText.KEY_FILE_MENU_OPEN_FILE, FileMenu.OPEN_FILE, shortcuts, Shortcuts.CMD_OPEN_FILE)


	_file_menu.add_child(_recents_submenu)
	_add_submenu_item(_file_menu, InterfaceText.KEY_FILE_MENU_OPEN_RECENT_FILE, _recents_submenu.name, FileMenu.OPEN_RECENT)

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

	_add_check_item(
		_tool_menu,
		InterfaceText.KEY_TOOL_MENU_FOLLOW_EXECUTION,
		ToolMenu.FOLLOW_EXECUTING_LINE,
		true
	)

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

	_add_separator(_tool_menu, InterfaceText.KEY_DIALOGUE)

	_add_item(_tool_menu, InterfaceText.KEY_GENERATE_LINE_IDS, ToolMenu.GENERATE_IDS)
	_add_item(_tool_menu, InterfaceText.KEY_CREATE_CSV, ToolMenu.CREATE_CSV)


func _initilize_help_menu(_shortcuts):
	$help_menu.text = InterfaceText.get_string(InterfaceText.KEY_MENU_HELP)
	_help_menu.id_pressed.connect(_on_help_menu_item_selected)

	_help_menu.clear()
	_help_menu.add_icon_item(
		get_theme_icon("ExternalLink", "EditorIcons"),
		InterfaceText.get_string(InterfaceText.KEY_HELP_ONLINE_DOCS),
		HelpMenu.ONLINE_DOCS
	)
	_help_menu.add_icon_item(
		get_theme_icon("ExternalLink", "EditorIcons"),
		InterfaceText.get_string(InterfaceText.KEY_HELP_REPORT_ISSUE),
		HelpMenu.REPORT_ISSUE
	)
	_help_menu.add_item("v%s" % InterfaceText.plugin_version, HelpMenu.VERSION)
	_help_menu.set_item_disabled(_help_menu.get_item_index(HelpMenu.VERSION), true)


func _initialize_recents_submenu():
	_setup_empty_recents()


func _setup_empty_recents():
	_add_item(_recents_submenu, InterfaceText.KEY_FILE_MENU_OPEN_RECENT_NO_RECENTS, 99)
	_recents_submenu.set_item_disabled(_recents_submenu.get_item_index(99), true)


func _create_recents_submenu():
	var recents_submenu = PopupMenu.new()
	recents_submenu.name = "recents"
	recents_submenu.id_pressed.connect(_on_recents_menu_item_selected)
	return recents_submenu


func _on_file_menu_item_selected(id: int):
	if _file_menu_triggers.has(id):
		_file_menu_triggers[id].emit()


func _on_tool_menu_item_selected(id: int):
	if _tool_menu_triggers.has(id):
		_tool_menu_triggers[id].emit()


func _on_recents_menu_item_selected(id: int):
	if id == RecentSubMenu.CLEAR_RECENTS:
		clear_recent_files_triggered.emit()
		return
	if id == 99:
		return

	recent_file_triggered.emit(_recent_files_paths[id])


func _on_help_menu_item_selected(id: int):
	if _help_menu_triggers.has(id):
		_help_menu_triggers[id].emit()


func _initialize_right_icons(_shortcuts):
	_execute_dialogue.icon = get_theme_icon("Play", "EditorIcons")
	_execute_dialogue.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_EXECUTE_DIALOGUE)

	_dock_button.icon = get_theme_icon("MakeFloating", "EditorIcons")
	_dock_button.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DOCK_WINDOW)


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


func set_follow_executing_line(should_sync: bool):
	var toggle_index = _tool_menu.get_item_index(ToolMenu.FOLLOW_EXECUTING_LINE)
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


func _add_submenu_item(menu: PopupMenu, text_key: String, submenu_key: String, id: int):
	menu.add_submenu_item(InterfaceText.get_string(text_key), submenu_key, id)


func set_recents(recent_files: Array):
	_recents_submenu.clear()
	if recent_files.is_empty():
		_setup_empty_recents()
		return
	_recent_files_paths = recent_files
	for path in _recent_files_paths:
		_recents_submenu.add_item(path.get_file())
	_recents_submenu.add_separator()
	_add_item(_recents_submenu, InterfaceText.KEY_FILE_MENU_RECENT_CLEAR_RECENTS, RecentSubMenu.CLEAR_RECENTS)


func _on_dock_button_pressed() -> void:
	dock_button_pressed.emit()
