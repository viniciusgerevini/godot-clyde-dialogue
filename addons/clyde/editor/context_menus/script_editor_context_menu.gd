extends "./context_menu_base.gd"

signal line_id_generation_requested


func _register_extra_menus() -> void:
	add_context_menu_item(
		InterfaceText.get_string(InterfaceText.KEY_GENERATE_LINE_IDS),
		_generate_line_ids,
	)


func _generate_line_ids(file) -> void:
	line_id_generation_requested.emit(file.resource_path)
