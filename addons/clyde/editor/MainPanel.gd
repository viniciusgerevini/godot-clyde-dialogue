@tool
extends MarginContainer

const DebugPanel = preload("./player/debug_dock.tscn")
const InterfaceText = preload("./config/interface_text.gd")
const Settings = preload("./config/settings.gd")

var _settings = Settings.new()

@onready
var editor = $HSplitContainer/VBoxContainer/HSplitContainer/MultiEditor
@onready
var block_list = $HSplitContainer/VBoxContainer/HSplitContainer/Lists/VSplitContainer/BlockList
@onready
var file_list = $HSplitContainer/VBoxContainer/HSplitContainer/Lists/VSplitContainer/FileList

@onready
var lists_container = $HSplitContainer/VBoxContainer/HSplitContainer/Lists

@onready
var top_bar = $HSplitContainer/VBoxContainer/TopBar

@onready
var player = $HSplitContainer/Player

var _current_file_path = ""
var _open_files = []

var _should_sync_editor_and_player = true

var editor_plugin: EditorPlugin

var _debug_panel

# TODO save layout
# TODO save open files
# TODO save config
# TODO files
#   - open from file system
#   - close from list
#   - reload from system
#   - persist open file list
#   -  prompt save
# TODO drag and drop from filesystem to file list
# TODO re-order opened files in list
# TODO double click open from filesystem, is it possible?

# TODO fix current problems (it seems partial dialogues can cause an infinite loop (i.e. -)
#   -- lexer has a bunch of issues with lookups


func _ready():
	_load_config()
	# TODO load from saved cache
	_open_files = []

	for key in _open_files:
		file_list.add_file(key)

	editor.switch_editor(_current_file_path)

	self.tree_exiting.connect(_on_tree_exiting)


func _on_block_list_block_selected(line, column):
	editor.go_to_position(line, column)


func _on_file_list_file_selected(file_path):
	if file_path == _current_file_path:
		return
	_current_file_path = file_path
	editor.switch_editor(_current_file_path)
	_load_blocks()


func _on_multi_editor_content_changed():
	if _current_file_path == "":
		return
	var should_refresh_file = file_list.open_file_count() == 0
	file_list.mark_edited(_current_file_path)
	_load_blocks()
	if should_refresh_file:
		_refresh_top_bar()


func _on_multi_editor_editor_removed(key: String):
	file_list.remove_file(key)
	if file_list.open_file_count() == 0:
		_refresh_top_bar()


func _on_multi_editor_parsing_finished(result):
	block_list.call_deferred("load_file", _current_file_path, result.blocks)
	if player.visible and _should_sync_editor_and_player:
		_on_top_bar_execute_dialogue()



func _on_multi_editor_editor_switched(key):
	if key == _current_file_path:
		return
	file_list.select_file(key)
	_current_file_path = key
	_load_blocks()


func _on_top_bar_open_file_triggered():
	_open_file_dialog()


func _on_top_bar_new_file_triggered():
	var file_dialog = _create_save_file_dialogue()
	file_dialog.title = "New dialogue file..."
	file_dialog.file_selected.connect(_on_new_file_dialog_file_selected.bind(file_dialog))
	file_dialog.popup_centered_ratio()
	# TODO open in dialogue folder by default
	#if _source != "":
		#_file_dialog_aseprite.current_dir = ProjectSettings.globalize_path(_source.get_base_dir())


func _on_top_bar_reload_from_disk():
	if file_list.is_unsaved(_current_file_path):
		print("show warning")

	editor.set_content(_load_file_content(_current_file_path))


func _on_top_bar_save_all_triggered():
	var open_files = file_list.get_open_files_paths()
	for o in open_files:
		if file_list.is_unsaved(o):
			_save_file(o, editor.get_content(o))
			file_list.mark_saved(o)
	EditorInterface.get_resource_filesystem().scan()


func _on_top_bar_save_as_triggered():
	var file_dialog = _create_save_file_dialogue()
	file_dialog.title = "Save dialogue as..."
	file_dialog.file_selected.connect(_on_save_as_dialog_file_selected.bind(file_dialog))
	file_dialog.popup_centered_ratio()


func _on_top_bar_save_file_triggered():
	_save_file(_current_file_path, editor.get_content())
	file_list.mark_saved(_current_file_path)
	EditorInterface.get_resource_filesystem().scan()


func _on_top_bar_show_in_filesystem_triggered():
	if _current_file_path != "":
		EditorInterface.get_file_system_dock().navigate_to_path(ProjectSettings.localize_path(_current_file_path))


func _on_top_bar_close_all_triggered():
	var open_files = file_list.get_open_files_paths()
	var should_notify_unsaved = false
	for o in open_files:
		if file_list.is_unsaved(o):
			should_notify_unsaved = true
		else:
			editor.remove_editor(o)

	# TODO show confirmation to delete unsaved as well


func _on_top_bar_close_file_triggered():
	if file_list.is_unsaved(_current_file_path):
		print("show warning")
	editor.remove_editor(_current_file_path)


func _on_top_bar_close_other_triggered():
	var open_files = file_list.get_open_files_paths()
	var should_notify_unsaved = false
	for o in open_files:
		if o == _current_file_path:
			continue

		if file_list.is_unsaved(o):
			should_notify_unsaved = true
		else:
			editor.remove_editor(o)
	# TODO show confirmation to remove unsaved blah
	# don't forget to skip current


func _refresh_top_bar():
	top_bar.refresh(file_list.open_file_count())


func _load_blocks():
	var parsed_doc = editor.get_parsed_document() if _current_file_path != "" else null
	if parsed_doc != null:
		block_list.load_file(_current_file_path, parsed_doc.blocks)
	else:
		block_list.load_file(_current_file_path, [])


func _open_file_dialog():
	# TODO support opening multiple files
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.file_selected.connect(_on_open_dialog_file_selected.bind(file_dialog))
	file_dialog.set_filters(PackedStringArray(["*.clyde"]))

	get_parent().add_child(file_dialog)
	# TODO open in dialogue folder by default
	#if _source != "":
		#_file_dialog_aseprite.current_dir = ProjectSettings.globalize_path(_source.get_base_dir())
	file_dialog.popup_centered_ratio()


func _on_open_dialog_file_selected(path, dialogue_modal):
	var content = _load_file_content(path)
	file_list.add_file(path)
	_current_file_path = path
	editor.switch_editor(_current_file_path)
	editor.set_content(content)
	file_list.mark_saved(_current_file_path)
	file_list.select_file(path)
	dialogue_modal.queue_free()
	_refresh_top_bar()


func _load_file_content(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	return file.get_as_text()


func _create_save_file_dialogue():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.set_filters(PackedStringArray(["*.clyde"]))
	get_parent().add_child(file_dialog)
	return file_dialog


func _on_new_file_dialog_file_selected(path, dialogue_modal):
	_save_file(path, "")
	file_list.add_file(path)
	editor.switch_editor(path)
	file_list.select_file(path)
	dialogue_modal.queue_free()
	_refresh_top_bar()


func _on_save_as_dialog_file_selected(path, dialogue_modal):
	var content = editor.get_content()
	_save_file(path, content)
	file_list.add_file(path)
	editor.switch_editor(path)
	file_list.select_file(path)
	editor.set_content(content)
	dialogue_modal.queue_free()
	EditorInterface.get_resource_filesystem().scan()


func _save_file(path: String, content: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)


func _toggle_lists(persist_change: bool = true):
	lists_container.visible = not lists_container.visible
	top_bar.set_lists_visibility(lists_container.visible)

	if persist_change:
		_settings.set_config(_settings.EDITOR_CFG_SHOW_LISTS, lists_container.visible)


func _on_top_bar_toggle_file_list_triggered():
	_toggle_lists()


func _on_top_bar_toggle_player_triggered():
	_toggle_player()


func _toggle_player(persist_change: bool = true):
	player.visible = not player.visible
	top_bar.set_player_visibility(player.visible)

	if persist_change:
		_settings.set_config(_settings.EDITOR_CFG_SHOW_PLAYER, player.visible)


func _on_top_bar_execute_dialogue():
	editor.clear_executing_line()
	var doc = editor.get_parsed_document()
	if doc == null:
		return
	if not player.visible:
		_toggle_player()

	var old_dialogue = player._dialogue_key
	player.set_dialogue(_current_file_path, doc)

	if old_dialogue != _current_file_path and _debug_panel != null:
		_debug_panel.load_data(player.get_data(), true)


func _on_player_content_finished_changing(dialogue_key, content):
	if content.type == "end":
		editor.clear_executing_line(dialogue_key)
		return
	if content.has("meta"):
		editor.set_executing_line(dialogue_key, content.meta.line)


func _on_player_dialogue_reset(dialogue_key):
	editor.clear_executing_line(dialogue_key)


func _on_player_position_selected(dialogue_key, line, column):
	if dialogue_key != _current_file_path:
		if not editor.has_editor(dialogue_key):
			return
		editor.switch_editor(dialogue_key)
	editor.go_to_position(line, column)


func _on_top_bar_toggle_player_sync():
	_toggle_player_sync()


func _toggle_player_sync(persist_change: bool = true):
	_should_sync_editor_and_player = not _should_sync_editor_and_player
	top_bar.set_editor_sync(_should_sync_editor_and_player)

	if persist_change:
		_settings.set_config(_settings.EDITOR_CFG_SYNC_PLAYER, _should_sync_editor_and_player)


func _on_player_toggle_debug_panel(is_visible):
	if is_visible:
		_create_debug_panel()
	else:
		_remove_debug_panel()


func _create_debug_panel():
	if _debug_panel != null:
		editor_plugin.add_control_to_bottom_panel(_debug_panel, InterfaceText.get_string(InterfaceText.KEY_DEBUG_PANEL_NAME))
		editor_plugin.make_bottom_panel_item_visible(_debug_panel)
		return

	_debug_panel = DebugPanel.instantiate()
	editor_plugin.add_control_to_bottom_panel(_debug_panel, InterfaceText.get_string(InterfaceText.KEY_DEBUG_PANEL_NAME))
	_debug_panel.load_data(player.get_data())
	_debug_panel.variable_changed.connect(_on_debug_variable_changed)
	editor_plugin.make_bottom_panel_item_visible(_debug_panel)


func _remove_debug_panel():
	if is_instance_valid(_debug_panel) and is_instance_valid(editor_plugin) and _debug_panel.is_inside_tree():
		editor_plugin.remove_control_from_bottom_panel(_debug_panel)


func _on_tree_exiting():
	_remove_debug_panel()


func _on_debug_variable_changed(var_name: String, value):
	player.set_variable(var_name, value)


func _on_player_variable_changed(var_name, value, old_value):
	if _debug_panel != null:
		_debug_panel.set_variable(var_name, value, old_value)


func _on_player_event_triggered(event_name):
	if _debug_panel != null:
		_debug_panel.record_event(event_name)


func _on_player_dialogue_mem_clean():
	if _debug_panel != null:
		_debug_panel.load_data(player.get_data(), true)


func _load_config():
	var config = _settings.get_editor_config()

	if not config.get(_settings.EDITOR_CFG_SHOW_LISTS, true):
		_toggle_lists(false)

	if config.get(_settings.EDITOR_CFG_SHOW_PLAYER, false):
		_toggle_player(false)

	if not config.get(_settings.EDITOR_CFG_SYNC_PLAYER, true):
		_toggle_player_sync(false)
