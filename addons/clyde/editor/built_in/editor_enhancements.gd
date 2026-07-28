@tool
extends RefCounted

const ClydeEditorSettings = preload("../config/settings.gd")
const DialogueEditorDecorator = preload("../editor/dialogue_editor_decorator.gd")

static var _comment_shortcut: Shortcut

static func enhance(editor: CodeEdit, settings: ClydeEditorSettings) -> DialogueEditorDecorator:
	var dialogue_editor: DialogueEditorDecorator = DialogueEditorDecorator.new(editor, settings, true)
	_load_editor_comment_shortcut()
	_setup_event_listeners(dialogue_editor)
	return dialogue_editor

static func _load_editor_comment_shortcut() -> void:
	var settings := EditorInterface.get_editor_settings()
	_comment_shortcut = settings.get_shortcut("script_text_editor/toggle_comment")


static func _setup_event_listeners(editor: DialogueEditorDecorator) -> void:
	editor.get_code_edit().gui_input.connect(_on_editor_gui_input.bind(editor))


static func _on_editor_gui_input(event: InputEvent, editor: DialogueEditorDecorator) -> void:
	if event is InputEventKey and event.is_pressed():
		if _comment_shortcut.matches_event(event):
			editor.toggle_comment()
			editor.get_code_edit().get_viewport().set_input_as_handled()
