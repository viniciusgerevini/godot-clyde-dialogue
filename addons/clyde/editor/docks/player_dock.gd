@tool
extends RefCounted

const ClydeEditorSettings = preload("../config/settings.gd")
const InterfaceText = preload("../config/interface_text.gd")
const PlayerDock = preload("../player/player_dock.tscn")
const BuiltInEditorFeatures = preload("../built_in/editor_features.gd")

var _dock: EditorDock
var _player

func register_dock(editor_root: EditorPlugin, settings: ClydeEditorSettings, editor_features: BuiltInEditorFeatures) -> void:
	_dock = EditorDock.new()
	_dock.title = InterfaceText.get_string(InterfaceText.KEY_DIALOGUE_PLAYER)
	_dock.dock_icon = settings.get_plugin_icon()
	_dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	_player = PlayerDock.instantiate()
	_dock.add_child(_player)
	editor_root.add_dock(_dock)
	_player.setup(editor_root, settings, editor_features)


func unregister_dock(editor_root: EditorPlugin) -> void:
	editor_root.remove_dock(_dock)
	_dock.queue_free()
	_dock = null
	_player = null


func open_dock(dialogue_path: String) -> void:
	_player.set_dialogue_path(dialogue_path)
	if not _dock.visible:
		_dock.make_visible()
