extends "./wrapper.gd"

const InterfaceText = preload("../config/interface_text.gd")

var _editor_plugin: EditorPlugin
var _debug_panel: Control


func _init(editor_plugin: EditorPlugin) -> void:
	_editor_plugin = editor_plugin


func get_root_node() -> Node:
	return _editor_plugin.get_editor_interface().get_base_control()


func set_debug_panel(panel: Control) -> void:
	_debug_panel = panel
	_editor_plugin.add_control_to_bottom_panel(_debug_panel, InterfaceText.get_string(InterfaceText.KEY_DEBUG_PANEL_NAME))


func remove_debug_panel() -> void:
	if is_instance_valid(_debug_panel) and is_instance_valid(_editor_plugin) and _debug_panel.is_inside_tree():
		_editor_plugin.remove_control_from_bottom_panel(_debug_panel)


func make_debug_panel_visible() -> void:
	_editor_plugin.make_bottom_panel_item_visible(_debug_panel)
