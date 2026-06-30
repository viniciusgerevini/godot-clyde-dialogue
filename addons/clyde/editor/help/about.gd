@tool
extends Window

@onready var _title: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/title
@onready var _description: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/description
@onready var _version: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/version
@onready var license: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/license


func setup(window_title: String, about_title: String, description: String, version: String) -> void:
	self.title = window_title
	_title.text = about_title
	_description.text = description
	_version.text = "v%s" % version


func _on_close_requested() -> void:
	queue_free()


func _on_description_meta_clicked(meta: Variant) -> void:
	if meta == "LICENSE":
		license.visible = not license.visible
		if not license.visible:
			self.reset_size()
		return
	OS.shell_open(str(meta))


func set_license_notice(text: String) -> void:
	license.text = text
