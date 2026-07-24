extends RefCounted

const ClydeEditorSettings = preload("../config/settings.gd")
const ClydeGodotEditorSyntaxHighlighter = preload("../syntax/editor_syntax_highlighter.gd")
const EditorEnhancements = preload("./editor_enhancements.gd")

var _script_editor: ScriptEditor
var _settings: ClydeEditorSettings
var _editor_syntax_highlighter: ClydeGodotEditorSyntaxHighlighter

func _init(editor: ScriptEditor, settings: ClydeEditorSettings) -> void:
	_script_editor = editor
	_settings = settings
	_register_syntax_highlighter()


func unregister() -> void:
	_unregister_syntax_highligher()
	_script_editor = null


func _register_syntax_highlighter() -> void:
	_editor_syntax_highlighter = ClydeGodotEditorSyntaxHighlighter.new()
	_editor_syntax_highlighter.settings = _settings
	_editor_syntax_highlighter.new_highlighter_instantiated.connect(_on_new_highlighter_instantiated)
	_script_editor.register_syntax_highlighter(_editor_syntax_highlighter)


func _unregister_syntax_highligher() -> void:
	_script_editor.unregister_syntax_highlighter(_editor_syntax_highlighter)
	_editor_syntax_highlighter.new_highlighter_instantiated.disconnect(_on_new_highlighter_instantiated)
	_editor_syntax_highlighter = null


func _on_new_highlighter_instantiated(editor: CodeEdit) -> void:
	EditorEnhancements.enhance(editor, _settings)
