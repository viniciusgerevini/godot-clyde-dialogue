@tool
extends HBoxContainer

const Settings = preload("../config/settings.gd")
const InterfaceText = preload("../config/interface_text.gd")

signal save_pressed
signal edit_pressed
signal cancel_pressed
signal delete_pressed

var settings: Settings


func _ready():
	$save.icon = settings.get_theme_icon("save")
	$save.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_SAVE)
	$edit.icon = settings.get_theme_icon("edit")
	$edit.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_EDIT)
	$delete.icon = settings.get_theme_icon("remove")
	$delete.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_REMOVE)
	$cancel.icon = settings.get_theme_icon("close")
	$cancel.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_CANCEL)


func _on_save_pressed():
	idle_mode()
	save_pressed.emit()


func _on_cancel_pressed():
	idle_mode()
	cancel_pressed.emit()


func _on_edit_pressed():
	save_mode()
	edit_pressed.emit()


func _on_delete_pressed():
	delete_pressed.emit()


func save_mode(with_cancel: bool = false):
	$save.show()
	$delete.hide()
	$edit.hide()
	if with_cancel:
		$cancel.show()


func idle_mode():
	$save.hide()
	$cancel.hide()
	$delete.show()
	$edit.show()
