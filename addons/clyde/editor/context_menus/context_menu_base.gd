extends EditorContextMenuPlugin

signal player_requested(file_path: String)

const ClydeEditorSettings = preload("../config/settings.gd")
const InterfaceText = preload("../config/interface_text.gd")

func _popup_menu(paths: PackedStringArray) -> void:
	for path in paths:
		if path.ends_with(".clyde"):
			_register_menu(path)
			break


func _register_menu(path: String) -> void:
	add_context_menu_item(
		InterfaceText.get_string(InterfaceText.KEY_OPEN_IN_DIALOGUE_PLAYER),
		_open_in_dialogue_player,
		ClydeEditorSettings.get_plugin_icon()
	)


func _open_in_dialogue_player(file) -> void:
	player_requested.emit(file.resource_path)
