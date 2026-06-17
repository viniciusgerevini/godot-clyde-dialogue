@abstract extends RefCounted

@abstract func get_root_node() -> Node
@abstract func set_debug_panel(panel: Control) -> void
@abstract func remove_debug_panel() -> void
@abstract func make_debug_panel_visible() -> void
@abstract func create_file_dialog() -> FileDialog
