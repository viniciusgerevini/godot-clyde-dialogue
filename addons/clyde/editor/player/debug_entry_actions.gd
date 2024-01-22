@tool
extends HBoxContainer

const InterfaceText = preload("../config/interface_text.gd")

signal save_pressed
signal edit_pressed
signal cancel_pressed
signal delete_pressed


func _ready():
	$save.icon = get_theme_icon("Save", "EditorIcons")
	$save.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_SAVE)
	$edit.icon = get_theme_icon("Edit", "EditorIcons")
	$edit.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_EDIT)
	$delete.icon = get_theme_icon("Remove", "EditorIcons")
	$delete.tooltip_text = InterfaceText.get_string(InterfaceText.KEY_DEBUG_REMOVE)
	#$cancel.icon = get_theme_icon("Close", "EditorIcons")


func _on_save_pressed():
	_idle_mode()
	save_pressed.emit()


func _on_cancel_pressed():
	_idle_mode()
	cancel_pressed.emit()


func _on_edit_pressed():
	_save_mode()
	edit_pressed.emit()


func _on_delete_pressed():
	delete_pressed.emit()


func _save_mode():
	$save.show()
	#$cancel.show()
	$delete.hide()
	$edit.hide()


func _idle_mode():
	$save.hide()
	#$cancel.hide()
	$delete.show()
	$edit.show()
