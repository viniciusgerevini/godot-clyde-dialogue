@tool

const KEY_DEFAULT_BLOCK = "DEFAULT_BLOCK"
const KEY_NO_DIALOGUE = "NO_DIALOGUE"
const KEY_EXECUTE_DIALOGUE = "EXECUTE_DIALOGUE"
const KEY_DIALOGUE_END="DIALOGUE_END"
const KEY_DIALOGUE_LOADED="DIALOGUE_LOADED"
const KEY_DIALOGUE_NOT_LOADED="DIALOGUE_NOT_LOADED"
# player
const KEY_PLAYER_BLOCK_SELECTION_TOOLTIP = "PLAYER_BLOCK_SELECTION_TOOLTIP"
const KEY_PLAYER_RESTART_TOOLTIP = "PLAYER_RESTART_TOOLTIP"
const KEY_PLAYER_NEXT_LINE_TOOLTIP = "PLAYER_NEXT_LINE_TOOLTIP"
const KEY_PLAYER_FORWARD_TOOLTIP = "PLAYER_FORWARD_TOOLTIP"
const KEY_PLAYER_POLTERGEIST_TOOLTIP = "PLAYER_POLTERGEIST_TOOLTIP"
const KEY_PLAYER_CLEAR_MEM_TOOLTIP = "PLAYER_CLEAR_MEM_TOOLTIP"
const KEY_PLAYER_BALLOONS_TOOLTIP = "PLAYER_BALLOONS_TOOLTIP"
const KEY_PLAYER_SHOW_META_TOOLTIP = "PLAYER_SHOW_META_TOOLTIP"
const KEY_PLAYER_SHOW_DEBUG_TOOLTIP = "PLAYER_SHOW_DEBUG_TOOLTIP"
const KEY_PLAYER_DIALOGUE_STARTED = "PLAYER_DIALOGUE_STARTED_MESSAGE"

# top bar
const KEY_FILE_MENU_NEW_FILE = "FILE_MENU_NEW_FILE"
const KEY_FILE_MENU_OPEN_FILE = "FILE_MENU_OPEN_FILE"
const KEY_FILE_MENU_OPEN_RECENT_FILE = "FILE_MENU_OPEN_RECENT"
const KEY_FILE_MENU_OPEN_RECENT_NO_RECENTS = "FILE_MENU_OPEN_RECENT_NO_RECENTS"
const KEY_FILE_MENU_RECENT_CLEAR_RECENTS = "FILE_MENU_RECENT_CLEAR_RECENTS"
const KEY_FILE_MENU_SAVE_FILE = "FILE_MENU_SAVE_FILE"
const KEY_FILE_MENU_SAVE_AS = "FILE_MENU_SAVE_AS"
const KEY_FILE_MENU_SAVE_ALL = "FILE_MENU_SAVE_ALL"
const KEY_FILE_MENU_RELOAD_FROM_DISK = "FILE_MENU_RELOAD_FROM_DISK"
const KEY_FILE_MENU_SHOW_IN_FILESYSTEM = "FILE_MENU_SHOW_IN_FILESYSTEM"
const KEY_FILE_MENU_CLOSE = "FILE_MENU_CLOSE"
const KEY_FILE_MENU_CLOSE_ALL = "FILE_MENU_CLOSE_ALL"
const KEY_FILE_MENU_CLOSE_OTHER = "FILE_MENU_CLOSE_OTHER"
const KEY_TOOL_MENU_EDITOR_SECTION = "TOOL_MENU_EDITOR_SECTION"
const KEY_TOOL_MENU_PLAYER_SECTION = "TOOL_MENU_PLAYER_SECTION"
const KEY_TOOL_MENU_SHOW_LISTS = "TOOL_MENU_SHOW_LISTS"
const KEY_TOOL_MENU_SHOW_PLAYER = "TOOL_MENU_SHOW_PLAYER"
const KEY_TOOL_MENU_PLAYER_SYNC = "TOOL_MENU_PLAYER_SYNC"
const KEY_MENU_FILE = "MENU_FILE"
const KEY_MENU_TOOL = "MENU_TOOL"
const KEY_MENU_HELP = "MENU_HELP"
const KEY_DEBUG_PANEL_NAME = "DEBUG_PANEL_NAME"
const KEY_DEBUG_VARIABLES_LABEL = "DEBUG_VARIABLES_LABEL"
const KEY_DEBUG_HISTORY_LABEL = "DEBUG_HISTORY_LABEL"
const KEY_DEBUG_EVENT_LABEL = "DEBUG_EVENT_LABEL"
const KEY_DEBUG_VARIABLE_LABEL = "DEBUG_VARIABLE_LABEL"
const KEY_DEBUG_TIME = "DEBUG_TIME"
const KEY_DEBUG_TYPE = "DEBUG_TYPE"
const KEY_DEBUG_NAME = "DEBUG_NAME"
const KEY_DEBUG_VALUE = "DEBUG_VALUE"
const KEY_DEBUG_PREVIOUS_VALUE = "DEBUG_PREVIOUS_VALUE"
const KEY_DEBUG_EDIT = "DEBUG_EDIT"
const KEY_DEBUG_SAVE = "DEBUG_SAVE"
const KEY_DEBUG_REMOVE = "DEBUG_REMOVE"
const KEY_DEBUG_CANCEL = "DEBUG_CANCEL"
const KEY_DEBUG_ADD_VARIABLE = "DEBUG_ADD_VARIABLE"
const KEY_COPY_FILE_PATH = "COPY_FILE_PATH"
const KEY_FILTER_FILES = "FILTER_FILES"
const KEY_FILTER_BLOCKS = "FILTER_BLOCKS"
const KEY_SORT = "SORT"

static var _loaded_locale := "en"
static var _default_locale := "en"

static var _entries = {}
static var _fallback = {}

static func get_string(key: String) -> String:
	_fallback = {
		# TODO move those to csv file. Only here because godot editor cache static hard
		"DEFAULT_BLOCK": "Default",
		"NO_DIALOGUE": "No dialogue",
		"PLAYER_BLOCK_SELECTION_TOOLTIP": "Selected Block",
		"PLAYER_DIALOGUE_STARTED_MESSAGE": "dialogue started",
		"EXECUTE_DIALOGUE": "Execute Dialogue",
		"DIALOGUE_END": "dialogue ended",
		"DIALOGUE_LOADED": "dialogue loaded",
		"DIALOGUE_NOT_LOADED": "no dialogue loaded",
		"FILE_MENU_NEW_FILE": "New File...",
		"FILE_MENU_OPEN_FILE": "Open...",
		"FILE_MENU_OPEN_RECENT": "Open Recent",
		"FILE_MENU_RECENT_CLEAR_RECENTS": "Clear Recent Files",
		"FILE_MENU_OPEN_RECENT_NO_RECENTS": "No recent files",
		"FILE_MENU_SAVE_FILE": "Save",
		"FILE_MENU_SAVE_AS": "Save As...",
		"FILE_MENU_SAVE_ALL": "Save All",
		"FILE_MENU_RELOAD_FROM_DISK": "Reload from Disk",
		"FILE_MENU_SHOW_IN_FILESYSTEM": "Show in FileSystem",
		"FILE_MENU_CLOSE": "Close",
		"FILE_MENU_CLOSE_ALL": "Close All",
		"FILE_MENU_CLOSE_OTHER": "Close Others",
		"TOOL_MENU_SHOW_LISTS": "Show Lists",
		"TOOL_MENU_SHOW_PLAYER": "Show Dialogue Player",
		"MENU_FILE": "File",
		"MENU_TOOL": "Tool",
		"MENU_HELP": "Help",
		"TOOL_MENU_PLAYER_SECTION": "Player",
		"TOOL_MENU_EDITOR_SECTION": "Editor",
		"TOOL_MENU_PLAYER_SYNC": "Sync Changes with Player",
		"DEBUG_PANEL_NAME": "Clyde Debug",
		"DEBUG_VARIABLES_LABEL": "Variables",
		"DEBUG_HISTORY_LABEL": "History",
		"DEBUG_EVENT_LABEL": "event",
		"DEBUG_VARIABLE_LABEL": "variable",
		"DEBUG_TIME": "Time",
		"DEBUG_TYPE": "Type",
		"DEBUG_NAME": "Name",
		"DEBUG_VALUE": "Value",
		"DEBUG_PREVIOUS_VALUE": "Previous Value",
		"DEBUG_EDIT": "Edit",
		"DEBUG_SAVE": "Save",
		"DEBUG_REMOVE": "Remove",
		"DEBUG_ADD_VARIABLE": "Add Variable",
		"DEBUG_CANCEL": "Cancel",
		"COPY_FILE_PATH": "Copy File Path",
		"FILTER_FILES": "Filter Files",
		"FILTER_BLOCKS": "Filter Blocks",
		"SORT": "Sort",
	}
	_load_strings()
	if _entries.has(key):
		return _entries[key]
	return _fallback[key]


static func _load_strings() -> void:
	var locale = TranslationServer.get_tool_locale()
	if locale == _loaded_locale and not _entries.is_empty():
		return
	if not FileAccess.file_exists(_locale_translation_path(locale)):
		locale = _default_locale

	_load_entries_for_locale(_default_locale, _fallback)
	if locale != _default_locale:
		_load_entries_for_locale(locale, _entries)
	else:
		_entries = _fallback
	_loaded_locale = locale


static func _load_entries_for_locale(locale: String, dictionary: Dictionary) -> void:
	var file = FileAccess.open(_locale_translation_path(locale), FileAccess.READ)
	var header = file.get_csv_line()
	if header.size() < 2:
		return

	while file.get_position() < file.get_length():
		var line = file.get_csv_line()
		if line.size() < 2:
			continue
		dictionary[line[0]] = line[1]
	return


static func _locale_translation_path(locale: String) -> String:
	return "res://addons/clyde/editor/config/translations/%s.csv" % locale
