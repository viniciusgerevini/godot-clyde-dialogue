extends Panel

const AppSettings = preload("./app_settings.gd")
const Settings = preload("res://addons/clyde/editor/config/settings.gd")

@onready var _dialogue_editor: CodeEdit = $MarginContainer/HSplitContainer/Editor/DialogueEditor
@onready var _player: MarginContainer = $MarginContainer/HSplitContainer/Player/Player

var _dialogue_path: String = "in_memory_dialogue"

var _is_file_watch_enabled: bool = true
var _is_follow_line_enabled: bool = true

func _ready() -> void:
	var settings = Settings.new(AppSettings.new())
	_dialogue_editor.setup(settings)
	_player.setup(settings)

	var cfg = settings.get_editor_config()
	_is_file_watch_enabled = cfg.get(settings.EDITOR_CFG_PLAYER_WATCH_FILE, true)
	_is_follow_line_enabled = cfg.get(settings.EDITOR_CFG_EDITOR_FOLLOW_EXECUTION, true)


func _on_player_content_finished_changing(dialogue_key: String, content: Dictionary) -> void:
	if not _is_follow_line_enabled:
		return

	if content.type == ClydeDialogue.CONTENT_TYPE_END:
		_dialogue_editor.clear_executing_lines()
	else:
		_dialogue_editor.set_executing_line(content.meta.line)


func _on_player_position_selected(dialogue_key: String, line: int, column: int) -> void:
	_dialogue_editor.go_to_position(line, column)


func _on_player_dialogue_mem_clean() -> void:
	_dialogue_editor.clear_executing_lines()


func _on_player_dialogue_reset(dialogue_key: Variant) -> void:
	_dialogue_editor.clear_executing_lines()


func _on_player_event_triggered(event_name: Variant, parameters: Variant) -> void:
	print("Dialogue event triggered. Name: %s | Parameters: %s" % [ event_name, ",".join(parameters) ])


func _on_player_external_variable_changed(var_name: Variant, value: Variant, old_value: Variant) -> void:
	print("Dialogue external variable changed. Name: %s | New value: %s | Old value: %s" % [ var_name, value, old_value ])


func _on_player_variable_changed(var_name: Variant, value: Variant, old_value: Variant) -> void:
	print("Dialogue internal variable changed. Name: %s | New value: %s | Old value: %s" % [ var_name, value, old_value ])


func _on_player_watch_file_toggled(is_enabled: bool) -> void:
	_is_file_watch_enabled = is_enabled


func _on_player_follow_line_toggled(is_enabled: bool) -> void:
	_is_follow_line_enabled = is_enabled
	if not _is_follow_line_enabled:
		_dialogue_editor.clear_executing_lines()


func _on_player_toggle_debug_panel(is_visible: bool) -> void:
	print("Debugger not implemented in this demo")


func _on_dialogue_editor_parsing_finished() -> void:
	if _is_file_watch_enabled:
		_player.set_dialogue.call_deferred(_dialogue_path, _dialogue_editor.get_parsed_document())


func _on_dialogue_editor_parsing_failed(result: Dictionary) -> void:
	print("FAILED ", result)
