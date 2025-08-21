@tool
extends MarginContainer

signal dock_button_pressed

const DockableWindow = preload("./windows/dockable_window.gd")
const DebugPanel = preload("./player/debug_dock.tscn")
const InterfaceText = preload("./config/interface_text.gd")
const Settings = preload("./config/settings.gd")
const IdGenerator = preload("./tools/id_generator.gd")

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

@onready
var _csv_exporter_dialog = $CsvExporterWindow

var _current_file_path = ""
var _open_files = []
var _persisted_content = {}

var _should_sync_editor_and_player = true
var _should_follow_executing_line = true

var editor_plugin: EditorPlugin

var _debug_panel

var _dockable_player

func _ready():
	_configure_dockable_player()
	_load_config()
	_open_files = _load_open_files()
	_load_recents()

	for key in _open_files:
		_open_file(key, false, false)

	self.tree_exiting.connect(_on_tree_exiting)


func _configure_dockable_player() -> void:
	_dockable_player = DockableWindow.new(
		$HSplitContainer,
		editor_plugin.get_editor_interface().get_base_control(),
		player
	)
	_dockable_player.title = InterfaceText.get_string(InterfaceText.KEY_PLAYER_WINDOW_TITLE)
	_dockable_player.content_margin_left = 10
	_dockable_player.content_margin_right = 10
	_dockable_player.content_margin_bottom = 10

	_dockable_player.window_docked.connect(func():
		player.show_close_button()
	)
	_dockable_player.window_undocked.connect(func():
		player.hide_close_button()
	)

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
	if editor.get_content() != _persisted_content[_current_file_path]:
		file_list.mark_edited(_current_file_path)
	else:
		file_list.mark_saved(_current_file_path)
	_load_blocks()
	if should_refresh_file:
		_refresh_top_bar()


func _on_multi_editor_editor_removed(key: String):
	file_list.remove_file(key)
	_persisted_content.erase(key)
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
	file_dialog.title = InterfaceText.get_string(InterfaceText.KEY_FILE_MENU_NEW_FILE)
	file_dialog.file_selected.connect(_on_new_file_dialog_file_selected.bind(file_dialog))
	file_dialog.popup_centered_ratio()
	file_dialog.current_dir = ProjectSettings.globalize_path(_get_source_folder())


func _on_top_bar_reload_from_disk():
	if file_list.is_unsaved(_current_file_path):
		_unsaved_file_reload_confirmation_dialog()
		return
	_reload_current()


func _reload_current():
	var content = _load_file_content(_current_file_path)
	editor.set_content(content)
	file_list.mark_saved(_current_file_path)
	_persisted_content[_current_file_path] = content


func _on_top_bar_save_all_triggered():
	var open_files = file_list.get_open_files_paths()
	for o in open_files:
		if file_list.is_unsaved(o):
			_save_file(o, editor.get_content(o))
			file_list.mark_saved(o)
	EditorInterface.get_resource_filesystem().scan()


func _on_top_bar_save_as_triggered():
	var file_dialog = _create_save_file_dialogue()
	file_dialog.title = InterfaceText.get_string(InterfaceText.KEY_FILE_MENU_SAVE_AS)
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
	var remaining = []
	for o in open_files:
		if file_list.is_unsaved(o):
			should_notify_unsaved = true
			remaining.push_back(o)
		else:
			editor.remove_editor(o)

	_open_files = remaining

	if should_notify_unsaved:
		_multiple_unsaved_files_on_close_confirmation_dialog("close_all")


func _on_top_bar_close_file_triggered():
	if file_list.is_unsaved(_current_file_path):
		_unsaved_file_close_confirmation_dialog()
		return

	_close_current_file()


func _close_current_file():
	_open_files.erase(_current_file_path)
	editor.remove_editor(_current_file_path)


func _on_top_bar_close_other_triggered():
	var open_files = file_list.get_open_files_paths()
	var should_notify_unsaved = false
	var remaining = []
	for o in open_files:
		if o == _current_file_path:
			remaining.push_back(_current_file_path)
			continue

		if file_list.is_unsaved(o):
			should_notify_unsaved = true
			remaining.push_back(o)
		else:
			editor.remove_editor(o)

	_open_files = remaining

	if should_notify_unsaved:
		_multiple_unsaved_files_on_close_confirmation_dialog("close_other")


func _refresh_top_bar():
	top_bar.refresh(file_list.open_file_count())


func _load_blocks():
	var parsed_doc = editor.get_parsed_document() if _current_file_path != "" else null
	if parsed_doc != null:
		block_list.load_file(_current_file_path, parsed_doc.blocks)
	else:
		block_list.load_file(_current_file_path, [])


func _open_file_dialog():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.files_selected.connect(_on_open_dialog_file_selected.bind(file_dialog))
	file_dialog.set_filters(PackedStringArray(["*.clyde"]))
	file_dialog.current_dir = ProjectSettings.globalize_path(_get_source_folder())

	get_parent().add_child(file_dialog)
	file_dialog.popup_centered_ratio()


func _on_open_dialog_file_selected(paths, dialogue_modal):
	dialogue_modal.queue_free()

	for path in paths:
		_open_file(path)


func _open_file(path, include_in_open_list: bool = true, include_in_recents: bool = true):
	var content = _load_file_content(path)
	_persisted_content[path] = content
	file_list.add_file(path)
	_current_file_path = path
	editor.switch_editor(_current_file_path)
	editor.set_content(content)
	editor.clear_undo_history()
	file_list.mark_saved(_current_file_path)
	file_list.select_file(path)
	if include_in_open_list:
		_open_files.push_back(path)
	if include_in_recents:
		_add_recent(path)
	_refresh_top_bar()


func _load_file_content(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	return file.get_as_text()


func _create_save_file_dialogue() -> EditorFileDialog:
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
	_persisted_content[path] = content


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
	doc.doc_path = _current_file_path
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
	_debug_panel.load_external_variables(player.get_external_variables())
	_debug_panel.variable_changed.connect(_on_debug_variable_changed)
	_debug_panel.external_variable_changed.connect(_on_debug_external_variable_changed)
	editor_plugin.make_bottom_panel_item_visible(_debug_panel)


func _remove_debug_panel():
	if is_instance_valid(_debug_panel) and is_instance_valid(editor_plugin) and _debug_panel.is_inside_tree():
		editor_plugin.remove_control_from_bottom_panel(_debug_panel)


func _on_tree_exiting():
	_settings.set_open_files(_open_files)
	_remove_debug_panel()


func _on_debug_variable_changed(var_name: String, value):
	player.set_variable(var_name, value)


func _on_debug_external_variable_changed(var_name: String, value):
	player.set_external_variable(var_name, value)


func _on_player_variable_changed(var_name, value, old_value):
	if _debug_panel != null:
		_debug_panel.set_variable(var_name, value, old_value)


func _on_player_external_variable_changed(var_name, value, old_value):
	if _debug_panel != null:
		_debug_panel.set_external_variable(var_name, value, old_value)


func _on_player_event_triggered(event_name, parameters):
	if _debug_panel != null:
		_debug_panel.record_event(event_name, parameters)


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

	if not config.get(_settings.EDITOR_CFG_EDITOR_FOLLOW_EXECUTION, true):
		_toggle_follow_execution(false)


func _load_open_files() -> Array:
	return _settings.get_open_files().filter(func(path): return FileAccess.file_exists(path))


func _on_top_bar_clear_recent_files_triggered():
	_settings.clear_recents()
	top_bar.set_recents([])


func _on_top_bar_recent_file_triggered(file_path):
	if _open_files.has(file_path):
		editor.switch_editor(file_path)
		return
	if not FileAccess.file_exists(file_path):
		return

	_open_file(file_path)


func _add_recent(recent_path):
	_settings.add_recent(recent_path)
	top_bar.set_recents(_settings.get_recents())


func _load_recents():
	top_bar.set_recents(_settings.get_recents())


func _on_file_list_close_all_triggered():
	_on_top_bar_close_all_triggered()


func _on_file_list_close_file_triggered():
	_on_top_bar_close_file_triggered()


func _on_file_list_close_other_triggered():
	_on_top_bar_close_other_triggered()


func _on_file_list_reload_from_disk():
	_on_top_bar_reload_from_disk()


func _on_file_list_save_as_triggered():
	_on_top_bar_save_as_triggered()


func _on_file_list_save_file_triggered():
	_on_top_bar_save_file_triggered()


func _on_file_list_show_in_filesystem_triggered():
	_on_top_bar_show_in_filesystem_triggered()


func _on_file_list_copy_current_path_triggered():
	DisplayServer.clipboard_set(ProjectSettings.localize_path(_current_file_path))


func _unsaved_file_reload_confirmation_dialog():
	var c = AcceptDialog.new()
	c.title = InterfaceText.get_string(InterfaceText.KEY_FILE_MENU_RELOAD_FROM_DISK)
	c.dialog_text = "%s\n(%s)" % [
		InterfaceText.get_string(InterfaceText.KEY_RELOAD_UNSAVED_FILE),
		_current_file_path.get_file()
	]
	c.ok_button_text = InterfaceText.get_string(InterfaceText.KEY_FILE_MENU_RELOAD_FROM_DISK)
	c.add_cancel_button(InterfaceText.get_string(InterfaceText.KEY_DEBUG_CANCEL))
	c.confirmed.connect(_on_reload_unsaved_confirmed.bind(c))
	c.canceled.connect(_on_unsaved_close_canceled.bind(c))
	add_child(c)
	c.popup_centered()


func _unsaved_file_close_confirmation_dialog():
	var c = AcceptDialog.new()
	c.title = InterfaceText.get_string(InterfaceText.KEY_FILE_MENU_CLOSE)
	c.dialog_text = "%s\n(%s)" % [
		InterfaceText.get_string(InterfaceText.KEY_CLOSE_UNSAVED_FILE_MESSAGE),
		_current_file_path.get_file()
	]
	c.ok_button_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_SAVE)
	c.add_button(InterfaceText.get_string(InterfaceText.KEY_DISCARD), false, "discard")
	c.add_cancel_button(InterfaceText.get_string(InterfaceText.KEY_DEBUG_CANCEL))
	c.confirmed.connect(_on_unsaved_close_confirmed.bind(c))
	c.canceled.connect(_on_unsaved_close_canceled.bind(c))
	c.custom_action.connect(_on_unsaved_close_action.bind(c))
	add_child(c)
	c.popup_centered()


func _on_unsaved_close_confirmed(c):
	_save_file(_current_file_path, editor.get_content())
	EditorInterface.get_resource_filesystem().scan()
	c.queue_free()
	_close_current_file()


func _on_unsaved_close_canceled(c):
	c.queue_free()


func _on_unsaved_close_action(action_name: String, c):
	if action_name == "discard":
		_close_current_file()
	c.queue_free()


func _on_multiple_unsaved_discard(action_name: String, c):
	c.queue_free()
	for o in _open_files:
		if o != _current_file_path:
			editor.remove_editor(o)

	if action_name == "close_all":
		editor.remove_editor(_current_file_path)
		_open_files = []
	else:
		_open_files = [_current_file_path]


func _multiple_unsaved_files_on_close_confirmation_dialog(close_action: String):
	var c = AcceptDialog.new()
	c.title = InterfaceText.get_string(InterfaceText.KEY_FILE_MENU_CLOSE)
	c.dialog_text = InterfaceText.get_string(InterfaceText.KEY_CLOSE_UNSAVED_FILES_MESSAGE)
	c.ok_button_text = InterfaceText.get_string(InterfaceText.KEY_DISCARD)
	c.add_cancel_button(InterfaceText.get_string(InterfaceText.KEY_DEBUG_CANCEL))
	c.confirmed.connect(_on_multiple_unsaved_discard.bind(close_action, c))
	c.canceled.connect(_on_unsaved_close_canceled.bind(c))
	add_child(c)
	c.popup_centered()


func _on_reload_unsaved_confirmed(c):
	_reload_current()
	c.queue_free()


func _get_source_folder():
	return ProjectSettings.get_setting("dialogue/source_folder") if ProjectSettings.has_setting("dialogue/source_folder") else "res://dialogues/"


func _on_top_bar_create_csv_triggered():
	var parsed = editor.get_parsed_document()
	if parsed == null:
		printerr("dialogue not compiled")
	_csv_exporter_dialog.set_current_file(_current_file_path, parsed)
	_csv_exporter_dialog.popup_centered()


func _on_top_bar_generate_ids_triggered():
	var current_content = editor.get_content()

	if current_content == "":
		return

	var id_generator = IdGenerator.new()
	var new_content = id_generator.add_ids_to_content(current_content)
	editor.set_content(new_content)
	file_list.mark_edited(_current_file_path)


func _on_top_bar_open_online_docs_triggered():
	OS.shell_open(_settings.ONLINE_DOCS_URL)


func _on_top_bar_report_issue_triggered():
	OS.shell_open(_settings.REPORT_ISSUE_URL)


func _on_top_bar_toggle_follow_execution():
	_toggle_follow_execution(true)


func _toggle_follow_execution(should_persist: bool = true):
	_should_follow_executing_line = not _should_follow_executing_line
	top_bar.set_follow_executing_line(_should_follow_executing_line)
	if should_persist:
		_settings.set_config(_settings.EDITOR_CFG_EDITOR_FOLLOW_EXECUTION, _should_follow_executing_line)
		editor.refresh_config()


func _on_csv_file_selected(path: String, dialog: EditorFileDialog):
	dialog.queue_free()


func prepare_for_project_run():
	_on_top_bar_save_all_triggered()


func load_file(path):
	_open_file(ProjectSettings.globalize_path(path))


func _on_player_close_triggered():
	_toggle_player()
	if not player.visible:
		editor.clear_executing_line(player._dialogue_key)



func _on_top_bar_dock_button_pressed() -> void:
	dock_button_pressed.emit()
