@tool
extends MarginContainer

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
# TODO notify when editor and player are out of sync
# TODO auto execute option

# TODO config: should validate dialogue?

# TODO fix current problems (it seems partial dialogues can cause an infinite loop (i.e. -)
#   -- lexer has a bunch of issues with lookups
func _ready():
	# TODO load from saved cache
	_open_files = []

	for key in _open_files:
		file_list.add_file(key)

	editor.switch_editor(_current_file_path)


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
	# TODO config to stop this
	if player.visible:
		_on_top_bar_execute_dialogue()



func _on_multi_editor_editor_switched(key):
	if key == _current_file_path:
		return
	file_list.select_file(key)
	_current_file_path = key
	_load_blocks()


func _on_top_bar_open_file_triggered():
	var my_theme = EditorInterface.get_editor_settings().get_setting("interface/theme/preset")
	print(my_theme)
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


func _toggle_lists():
	lists_container.visible = not lists_container.visible
	top_bar.set_lists_visibility(lists_container.visible)


func _on_multi_editor_toggle_interface_lists_requested():
	_toggle_lists()


func _on_top_bar_toggle_file_list_triggered():
	_toggle_lists()


func _on_top_bar_toggle_player_triggered():
	_toggle_player()


func _toggle_player():
	player.visible = not player.visible
	top_bar.set_player_visibility(player.visible)


func _on_top_bar_execute_dialogue():
	editor.clear_executing_line()
	var doc = editor.get_parsed_document()
	if doc == null:
		return
	if not player.visible:
		_toggle_player()

	player.set_dialogue(_current_file_path, doc)


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
