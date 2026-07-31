extends RefCounted

signal player_requested
signal csv_exporter_requested
signal about_requested

const InterfaceText = preload("../config/interface_text.gd")

const MENU_NAME = "Clyde Dialogue"

enum MenuItem {
	OPEN_PLAYER,
	CSV_EXPORTER,
	ABOUT,
}

func setup(editor_plugin: EditorPlugin) -> void:
	var menu = _create_menu()
	editor_plugin.add_tool_submenu_item(MENU_NAME, menu)


func remove(editor_plugin: EditorPlugin) -> void:
	editor_plugin.remove_tool_menu_item(MENU_NAME)


func _create_menu() -> PopupMenu:
	var menu := PopupMenu.new()

	menu.add_item(
		InterfaceText.get_string(InterfaceText.KEY_OPEN_DIALOGUE_PLAYER),
		MenuItem.OPEN_PLAYER
	)

	menu.add_item(
		InterfaceText.get_string(InterfaceText.KEY_CREATE_CSV),
		MenuItem.CSV_EXPORTER
	)

	menu.add_item(
		InterfaceText.get_string(InterfaceText.KEY_HELP_ABOUT),
		MenuItem.ABOUT
	)

	menu.id_pressed.connect(_on_item_selected)

	return menu


func _on_item_selected(id: int) -> void:
	match id:
		MenuItem.OPEN_PLAYER:
			player_requested.emit()
		MenuItem.CSV_EXPORTER:
			csv_exporter_requested.emit()
		MenuItem.ABOUT:
			about_requested.emit()
