@tool
extends MarginContainer

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")
const ParseWorker = preload("../parse_worker.gd")

var _parse_worker: ParseWorker
var _current_file_path: String = ""
var _parsed_doc: Dictionary
# - add menu on dialogue name:
#   - show current dialogue in script editor
#   - show current dialogue in file system
#   - close dialogue


# - player
#   - open files selector
# 	- open file menu
#   - menu with settings
#   - select current selected script editor file
#   - move player options to menu in player
#   - on click bubble, select right position in script file



# dialogue selector
# - on click, list all dialogues ope
# - get all open dialogues on startup


var _settings: Settings

@onready var _player: MarginContainer = $VBoxContainer/Player
@onready var _dialogue_path: LineEdit = $VBoxContainer/HBoxContainer/dialogue_path
@onready var _dialogue_menu: MenuButton = $VBoxContainer/HBoxContainer/dialogue_menu
@onready var _status: CenterContainer = $VBoxContainer/HBoxContainer/player_dock_status


const OPEN_DIALOGUE_ENTRY_ID: int = 9999999

var _is_file_watch_enabled: bool = true
var _is_follow_line_enabled: bool = true

var _is_new_parsing_execution: bool = false

func setup(settings: Settings) -> void:
	_settings = settings
	_player.setup(settings)

	_dialogue_menu.icon = get_theme_icon("Load", "EditorIcons")
	_dialogue_menu.get_popup().index_pressed.connect(_on_open_menu_index_pressed)

	_load_settings()
	_setup_parse_worker()


func _load_settings() -> void:
	var cfg = _settings.get_editor_config()
	_is_file_watch_enabled = cfg.get(_settings.EDITOR_CFG_PLAYER_WATCH_FILE, true)
	_is_follow_line_enabled = cfg.get(_settings.EDITOR_CFG_EDITOR_FOLLOW_EXECUTION, true)





	# on click dialogue menu load itesm
	# - first item Open File...
	#    - this will open file selector with .clyde as filter
	#    - on select file, open dialogue (should open script editor as well?)
	# - other items is the list of dialogues open in script editor
	#    - when script selected, load dialogue
	# - load icon in menu

	# - add spinner to signify dialogue is being parsed (maybe a message saying loading dialogue file)


# - dialogue player welcome screen?
#   - Open dialogue
#   - About
#   - Help

# drag and drop to player
#  - file system
#  - script editor

# script editor context menu
#  - Open in Dialogue Player

# settings to move action bar to the top

func _setup_parse_worker() -> void:
	_parse_worker = ParseWorker.new()
	_parse_worker.processing_finished.connect(_on_parsing_finished)
	_parse_worker.processing_failed.connect(_on_parsing_failed)


func _on_parsing_finished() -> void:
	_parsed_doc = _parse_worker.get_parse_result()
	_status.set_success()
	_player.set_dialogue.call_deferred(_current_file_path, _parsed_doc)


func _on_parsing_failed(result) -> void:
	if _is_new_parsing_execution:
		_is_new_parsing_execution = false
	_status.set_error(result.message)
	_player.add_event_line.call_deferred(result.message)


func set_dialogue_path(dialogue_path: String) -> void:
	_dialogue_path.text = dialogue_path.get_file()
	_dialogue_path.tooltip_text = dialogue_path
	_current_file_path = dialogue_path

	_player.clear_dialogue()
	_player.add_event_line(InterfaceText.get_string(InterfaceText.KEY_PLAYER_STATUS_LOADING))

	_parse_file(_current_file_path)


func _parse_file(dialogue_path: String) -> void:
	_status.set_loading()
	var file = FileAccess.open(dialogue_path, FileAccess.READ)
	if file == null:
		_status.set_error(file.get_open_error())
		_player.add_event_line.call_deferred(file.get_open_error())
		return
	var content = file.get_as_text()
	_parse_worker.parse(content)


func _on_dialogue_menu_about_to_popup() -> void:
	_load_open_paths()


func _load_open_paths() -> void:
	var menu: PopupMenu = _dialogue_menu.get_popup()
	menu.clear()

	menu.add_icon_item(
		get_theme_icon("Load", "EditorIcons"),
		InterfaceText.get_string(InterfaceText.KEY_PLAYER_OPEN_MENU),
		OPEN_DIALOGUE_ENTRY_ID
	)
	menu.add_separator()

	for file in _settings.get_open_dialogues_paths():
		menu.add_item(file)


func _on_open_menu_index_pressed(index: int) -> void:
	var menu: PopupMenu = _dialogue_menu.get_popup()
	var selected_id: int = menu.get_item_id(index)
	var item_value: String = menu.get_item_text(index)

	if selected_id == OPEN_DIALOGUE_ENTRY_ID:
		print("OPEN FILE SELECTOR")
		return

	set_dialogue_path(item_value)


func _on_player_content_finished_changing(dialogue_key: String, content: Dictionary) -> void:
	if _is_follow_line_enabled:
		print("FOLLOW LINE ")


func _on_player_follow_line_toggled(is_enabled: bool) -> void:
	_is_follow_line_enabled = is_enabled


func _on_player_watch_file_toggled(is_enabled: bool) -> void:
	_is_file_watch_enabled = is_enabled
	# TODO either start or stop watching


func _on_player_position_selected(dialogue_key: String, line: int, column: int) -> void:
	pass # Replace with function body.


func _on_player_toggle_debug_panel(is_visible: bool) -> void:
	pass # Replace with function body.


func _on_player_event_triggered(event_name: Variant, parameters: Variant) -> void:
	pass # Replace with function body.


func _on_player_external_variable_changed(var_name: Variant, value: Variant, old_value: Variant) -> void:
	pass # Replace with function body.


func _on_player_variable_changed(var_name: Variant, value: Variant, old_value: Variant) -> void:
	pass # Replace with function body.


func _on_player_dialogue_mem_clean() -> void:
	pass # Replace with function body.


func _on_player_dialogue_reset(dialogue_key: Variant) -> void:
	pass # Replace with function body.
