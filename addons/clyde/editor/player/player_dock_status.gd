@tool
extends CenterContainer

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")

@onready var _loading_icon: AnimatedSprite2D = $container/loading
@onready var _ok_icon: Sprite2D = $container/ok
@onready var _warning_icon: Sprite2D = $container/warning


func setup(settings: Settings) -> void:
	_ok_icon.hide()
	_warning_icon.hide()
	_loading_icon.hide()
	_configure_icons(settings)


func set_loading() -> void:
	_ok_icon.hide.call_deferred()
	_warning_icon.hide.call_deferred()
	_loading_icon.show.call_deferred()
	self.set_deferred("tooltip_text", InterfaceText.get_string(InterfaceText.KEY_PLAYER_STATUS_LOADING))


func set_success() -> void:
	_ok_icon.show.call_deferred()
	_warning_icon.hide.call_deferred()
	_loading_icon.hide.call_deferred()
	self.set_deferred("tooltip_text", InterfaceText.get_string(InterfaceText.KEY_PLAYER_STATUS_SUCCESS))


func set_error(error_message: String) -> void:
	_ok_icon.hide.call_deferred()
	_warning_icon.show.call_deferred()
	_loading_icon.hide.call_deferred()
	self.set_deferred("tooltip_text", "%s: %s" % [
		InterfaceText.get_string(InterfaceText.KEY_PLAYER_STATUS_FAIL),
		error_message
	])


func _configure_icons(settings: Settings):
	_loading_icon.sprite_frames.clear("default")
	for i in range(8):
		var icon = settings.get_theme_icon("progress_%s" % (i + 1))
		_loading_icon.sprite_frames.add_frame("default", icon)
	_loading_icon.play("default")

	_ok_icon.texture = settings.get_theme_icon("status_success")
	_warning_icon.texture = settings.get_theme_icon("status_error")
