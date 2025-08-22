@tool
extends Window

const InterfaceText = preload("../config/interface_text.gd")

var content_margin_left: int = -1
var content_margin_right: int = -1
var content_margin_top: int = -1
var content_margin_bottom: int = -1

func _ready() -> void:
	if self.title == "":
		self.title = InterfaceText.get_string(InterfaceText.KEY_EDITOR_WINDOW_TITLE)
	var p: StyleBoxFlat = $panel.get_theme_stylebox("panel")
	var p_color = EditorInterface.get_editor_settings().get_setting("interface/theme/base_color")
	p.bg_color = p_color
	p.content_margin_bottom = content_margin_bottom
	p.content_margin_top = content_margin_top
	p.content_margin_right = content_margin_right
	p.content_margin_left = content_margin_left


func add_panel(panel: Control) -> void:
	$panel.add_child(panel)


func remove_panel(panel: Control) -> void:
	$panel.remove_child(panel)
