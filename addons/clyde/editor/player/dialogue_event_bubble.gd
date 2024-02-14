@tool
extends VBoxContainer

@onready var _label = $PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _sublabel = $PanelContainer/MarginContainer/VBoxContainer/SubLabel


func _setup_color():
	var current_style = $PanelContainer.get_theme_stylebox("panel")
	var style = StyleBoxFlat.new()
	var color = current_style.get_bg_color().darkened(0.1)
	color.a = 0.8
	style.set_bg_color(color)
	style.set_corner_radius_all(5)
	$PanelContainer.add_theme_stylebox_override("panel", style)
	_label.modulate.a = 0.9
	_sublabel.modulate.a = 0.9


func set_label(text: String, sub_label):
	_setup_color()
	_label.text = text
	if sub_label != null:
		_sublabel.text = "[ %s ]" % sub_label
		_sublabel.show()
