@tool

const KEY_DEFAULT_BLOCK = "DEFAULT_BLOCK"
const KEY_NO_DIALOGUE = "NO_DIALOGUE"
const KEY_EXECUTE_DIALOGUE = "EXECUTE_DIALOGUE"
const KEY_DIALOGUE_END="DIALOGUE_END"
const KEY_DIALOGUE_LOADED="DIALOGUE_LOADED"
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
const KEY_MENU_FILE = "MENU_FILE"
const KEY_MENU_TOOL = "MENU_TOOL"
const KEY_MENU_HELP = "MENU_HELP"

static var _loaded_locale := "en"
static var _default_locale := "en"

static var _entries = {}
static var _fallback = {}

static func get_string(key: String) -> String:
	_fallback = {
		# TODO move those to csv file. Only here because godot editor cache static hard
		"DEFAULT_BLOCK": "Default",
		"NO_DIALOGUE": "No dialogue",
		"PLAYER_BLOCK_SELECTION_TOOLTIP": "Selected block",
		"PLAYER_DIALOGUE_STARTED_MESSAGE": "dialogue started",
		"EXECUTE_DIALOGUE": "Execute dialogue",
		"DIALOGUE_END": "dialogue ended",
		"DIALOGUE_LOADED": "dialogue loaded",
		"FILE_MENU_NEW_FILE": "New file...",
		"FILE_MENU_OPEN_FILE": "Open...",
		"FILE_MENU_SAVE_FILE": "Save",
		"FILE_MENU_SAVE_AS": "Save as...",
		"FILE_MENU_SAVE_ALL": "Save all",
		"FILE_MENU_RELOAD_FROM_DISK": "Reload from disk",
		"FILE_MENU_SHOW_IN_FILESYSTEM": "Show in FileSystem",
		"FILE_MENU_CLOSE": "Close",
		"FILE_MENU_CLOSE_ALL": "Close all",
		"FILE_MENU_CLOSE_OTHER": "Close others",
		"TOOL_MENU_SHOW_LISTS": "Show lists",
		"TOOL_MENU_SHOW_PLAYER": "Show dialogue player",
		"MENU_FILE": "File",
		"MENU_TOOL": "Tool",
		"MENU_HELP": "Help",
		"TOOL_MENU_PLAYER_SECTION": "Player",
		"TOOL_MENU_EDITOR_SECTION": "Editor",
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
		print(line)
		if line.size() < 2:
			continue
		dictionary[line[0]] = line[1]
	return


static func _locale_translation_path(locale: String) -> String:
	return "res://addons/clyde/editor/config/translations/%s.csv" % locale
