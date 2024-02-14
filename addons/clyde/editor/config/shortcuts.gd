extends RefCounted

var _shortcuts = {}

const CMD_LISTS_TOGGLE = "show_lists"
const CMD_PLAYER_TOGGLE = "toggle_player"
const CMD_NEW_FILE = "new_file"
const CMD_OPEN_FILE = "open_file"
const CMD_SAVE_FILE = "save_file"
const CMD_SAVE_ALL = "save_all"
const CMD_RELOAD_FILE = "reload_file"
const CMD_CLOSE_FILE = "close_file"
const CMD_EDITOR_TOGGLE_COMMENT = "editor_toggle_comment"
const CMD_EDITOR_EXECUTE_DIALOGUE = "editor_execute_dialogue"
const CMD_EDITOR_DELETE_LINE = "editor_delete_line"
const CMD_TOGGLE_WORD_WRAP = "toggle_word_wrap"
const CMD_EDITOR_FONT_SIZE_UP = "editor_font_size_up"
const CMD_EDITOR_FONT_SIZE_DOWN = "editor_font_size_down"
const CMD_EDITOR_FONT_SIZE_RESET = "editor_font_size_reset"
const CMD_EDITOR_SEARCH = "editor_search"

func _init():
	_shortcuts = _load_shortcuts()


func _load_shortcuts():
	return {
		CMD_LISTS_TOGGLE: [
			 { "key": KEY_BACKSLASH, "is_command_or_control_pressed": true },
		],
		CMD_PLAYER_TOGGLE: [
			 { "key": KEY_P, "is_command_or_control_pressed": true },
		],
		CMD_NEW_FILE: [
			 { "key": KEY_N, "is_command_or_control_pressed": true },
		],
		CMD_OPEN_FILE: [
			 { "key": KEY_O, "is_command_or_control_pressed": true },
		],
		CMD_SAVE_FILE: [
			 { "key": KEY_S, "is_command_or_control_pressed": true },
		],
		CMD_SAVE_ALL: [
			 { "key": KEY_S, "is_command_or_control_pressed": true, "is_shift_pressed": true },
		],
		CMD_CLOSE_FILE: [
			 { "key": KEY_W, "is_command_or_control_pressed": true },
		],
		CMD_RELOAD_FILE: [
			 { "key": KEY_R, "is_command_or_control_pressed": true, "is_alt_pressed": true },
		],
		CMD_EDITOR_TOGGLE_COMMENT: [
			 { "key": KEY_K, "is_command_or_control_pressed": true },
			 { "key": KEY_SLASH, "is_command_or_control_pressed": true },
		],
		CMD_EDITOR_DELETE_LINE: [
			 { "key": KEY_K, "is_command_or_control_pressed": true, "is_shift_pressed": true },
		],
		CMD_EDITOR_EXECUTE_DIALOGUE: [
			 { "key": KEY_X, "is_command_or_control_pressed": true, "is_shift_pressed": true },
		],
		CMD_TOGGLE_WORD_WRAP: [
			 { "key": KEY_Z, "is_alt_pressed": true },
		],
		CMD_EDITOR_FONT_SIZE_UP: [
			 { "key": KEY_EQUAL, "is_command_or_control_pressed": true },
		],
		CMD_EDITOR_FONT_SIZE_DOWN: [
			 { "key": KEY_MINUS, "is_command_or_control_pressed": true },
		],
		CMD_EDITOR_FONT_SIZE_RESET: [
			 { "key": KEY_0, "is_command_or_control_pressed": true },
		],
		CMD_EDITOR_SEARCH: [
			 { "key": KEY_F, "is_command_or_control_pressed": true },
		]
	}


func get_events_for_command(command: String) -> Array[InputEventKey]:
	var shortcuts = _shortcuts.get(command, [])
	var events: Array[InputEventKey] = []
	for shortcut in shortcuts:
		var event = InputEventKey.new()
		event.keycode = shortcut.key
		event.ctrl_pressed = shortcut.get("is_ctrl_pressed", false)
		event.meta_pressed = shortcut.get("is_meta_pressed", false)
		event.alt_pressed = shortcut.get("is_alt_pressed", false)
		event.shift_pressed = shortcut.get("is_shift_pressed", false)
		event.command_or_control_autoremap = shortcut.get("is_command_or_control_pressed", false)
		events.push_back(event)
	return events


func get_shortcut_for_command(command: String) -> Shortcut:
	var shortcut := Shortcut.new()
	shortcut.set_events(get_events_for_command(command))
	return shortcut
