@tool
extends MarginContainer

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")
const ParseWorker = preload("../parse_worker.gd")
const BuiltInEditorFeatures = preload("../built_in/editor_features.gd")
const DebugPanel = preload("./debug_dock.tscn")
const AppRoot = preload("../app_root/wrapper.gd")

var _parse_worker: ParseWorker
var _current_file_path: String = ""
var _parsed_doc: Dictionary

# - TODO dots dialgoue menu:
#   - show current dialogue in script editor
#   - show current dialogue in file system
#   - close dialogue

# TODO drag and drop from file system and editor to player

# TODO on click dialogue menu load itesm
# - first item Open File...
#    - this will open file selector with .clyde as filter
#    - on select file, open dialogue (should open script editor as well?)

# TODO dialogue player welcome screen?
#   - Open dialogue
#   - About
#   - Help

# TODO script editor context menu
#  - Open in Dialogue Player
#  - generate ids

var _settings: Settings
var _editor_features: BuiltInEditorFeatures
var _app_root: AppRoot
var _debug_panel

@onready var _player: MarginContainer = $VBoxContainer/Player
@onready var _dialogue_path: LineEdit = $VBoxContainer/HBoxContainer/dialogue_path
@onready var _dialogue_menu: MenuButton = $VBoxContainer/HBoxContainer/dialogue_menu
@onready var _status: CenterContainer = $VBoxContainer/HBoxContainer/player_dock_status


const OPEN_DIALOGUE_ENTRY_ID: int = 9999999

var _is_file_watch_enabled: bool = true
var _is_follow_line_enabled: bool = true

var _is_new_parsing_execution: bool = false

func setup(app_root: AppRoot, settings: Settings, editor_features: BuiltInEditorFeatures) -> void:
	_app_root = app_root
	_settings = settings
	_editor_features = editor_features
	_player.setup(settings)

	_dialogue_menu.icon = get_theme_icon("Load", "EditorIcons")
	_dialogue_menu.get_popup().index_pressed.connect(_on_open_menu_index_pressed)

	_load_settings()
	_setup_parse_worker()


func _load_settings() -> void:
	var cfg = _settings.get_editor_config()
	_is_file_watch_enabled = cfg.get(_settings.EDITOR_CFG_PLAYER_WATCH_FILE, true)
	_is_follow_line_enabled = cfg.get(_settings.EDITOR_CFG_EDITOR_FOLLOW_EXECUTION, true)


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
		# TODO open file selector
		return

	set_dialogue_path(item_value)


func _on_player_content_finished_changing(dialogue_key: String, content: Dictionary) -> void:
	if _is_follow_line_enabled:
		if _editor_features.has_open_editor_for_file(dialogue_key):
			var editor = _editor_features.get_editor_for_file(dialogue_key)

			if content.type == ClydeDialogue.CONTENT_TYPE_END:
				editor.clear_executing_line()
			else:
				_editor_features.open_file(dialogue_key)
				editor.set_executing_line(content.meta.line)


func _on_player_follow_line_toggled(is_enabled: bool) -> void:
	_is_follow_line_enabled = is_enabled


func _on_player_watch_file_toggled(is_enabled: bool) -> void:
	_is_file_watch_enabled = is_enabled
	# TODO either start or stop watching


func _on_player_position_selected(dialogue_key: String, line: int, column: int) -> void:
	if _editor_features.has_open_editor_for_file(dialogue_key):
		_editor_features.open_file(dialogue_key)
		var editor = _editor_features.get_editor_for_file(dialogue_key)
		editor.go_to_position(line, column)


func _on_player_toggle_debug_panel(is_visible: bool) -> void:
	if is_visible:
		_create_debug_panel()
	else:
		_remove_debug_panel()


func _on_player_event_triggered(event_name: Variant, parameters: Variant) -> void:
	if _debug_panel != null:
		_debug_panel.record_event(event_name, parameters)


func _on_player_external_variable_changed(var_name: Variant, value: Variant, old_value: Variant) -> void:
	if _debug_panel != null:
		_debug_panel.set_external_variable(var_name, value, old_value)


func _on_player_variable_changed(var_name: Variant, value: Variant, old_value: Variant) -> void:
	if _debug_panel != null:
		_debug_panel.set_variable(var_name, value, old_value)


func _on_player_dialogue_mem_clean() -> void:
	if _debug_panel != null:
		_debug_panel.load_data(_player.get_data(), true)


func _on_player_dialogue_reset(dialogue_key: Variant) -> void:
	if _editor_features.has_open_editor_for_file(dialogue_key):
		var editor = _editor_features.get_editor_for_file(dialogue_key)
		editor.clear_executing_line()


func _create_debug_panel() -> void:
	if _debug_panel != null:
		_app_root.set_debug_panel(_debug_panel)
		_app_root.make_debug_panel_visible()
		return
	_debug_panel = DebugPanel.instantiate()
	_app_root.set_debug_panel(_debug_panel)
	_debug_panel.load_data(_player.get_data())
	_debug_panel.load_external_variables(_player.get_external_variables())
	_debug_panel.variable_changed.connect(_on_debug_variable_changed)
	_debug_panel.external_variable_changed.connect(_on_debug_external_variable_changed)
	_app_root.make_debug_panel_visible()


func _remove_debug_panel() -> void:
	_app_root.remove_debug_panel()


func _on_debug_variable_changed(var_name: String, value) -> void:
	_player.set_variable(var_name, value)


func _on_debug_external_variable_changed(var_name: String, value) -> void:
	_player.set_external_variable(var_name, value)
