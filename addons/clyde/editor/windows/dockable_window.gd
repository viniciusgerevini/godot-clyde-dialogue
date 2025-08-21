extends RefCounted

signal window_docked
signal window_undocked

const ClydeEditorWindow = preload("res://addons/clyde/editor/windows/clyde_editor_window.tscn")

var _dock: Node
var _panel: Node
var _window_parent: Node
var _window: Window

var is_docked: bool = true

var title: String = ""
var content_margin_left: int = -1
var content_margin_right: int = -1
var content_margin_top: int = -1
var content_margin_bottom: int = -1

func _init(dock: Node, window_parent: Node, panel: Node) -> void:
	_dock = dock
	_panel = panel
	_window_parent = window_parent

	if not panel.is_inside_tree():
		_dock.add_child(panel)

	_panel.dock_button_pressed.connect(_on_dock_button_pressed)


func undock() -> void:
	_window = ClydeEditorWindow.instantiate()

	_window.title = title
	_window.content_margin_left = content_margin_left
	_window.content_margin_right = content_margin_right
	_window.content_margin_top = content_margin_top
	_window.content_margin_bottom = content_margin_bottom

	_dock.remove_child(_panel)
	_window.add_panel(_panel)
	_window_parent.add_child(_window)
	_window.popup_centered_ratio(0.5)
	_window.close_requested.connect(func():
		dock()
	)
	_panel.anchors_preset = Control.PRESET_FULL_RECT
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	is_docked = false
	window_undocked.emit()


func dock() -> void:
	_window.remove_panel(_panel)
	_window.queue_free()
	_dock.add_child(_panel)
	is_docked = true
	window_docked.emit()


func _on_dock_button_pressed():
	if is_docked:
		undock()
	else:
		dock()
