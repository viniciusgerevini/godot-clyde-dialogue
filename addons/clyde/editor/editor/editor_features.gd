extends RefCounted

const ClydeEditorSettings = preload("../config/settings.gd")
const ClydeGodotEditorSyntaxHighlighter = preload("../syntax/editor_syntax_highlighter.gd")
const EditorEnhancements = preload("./editor_enhancements.gd")
const DialogueEditorDecorator = preload("./dialogue_editor_decorator.gd")

var _script_editor: ScriptEditor
var _settings: ClydeEditorSettings
var _editor_syntax_highlighter: ClydeGodotEditorSyntaxHighlighter

var _open_files: Dictionary[String, DialogueEditorDecorator] = {}

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
	_register_open_file(EditorEnhancements.enhance(editor, _settings))


# Currently Godot does not provide any way to match the editor with its file path.
# My solution here is very hacky and brittle, but I will roll with it for now
func _register_open_file(dialogue_editor: DialogueEditorDecorator) -> void:
	var editor: CodeEdit = dialogue_editor.get_code_edit()
	# sorry
	await editor.get_tree().create_timer(0.5).timeout
	# I'm sorry
	var text_editor = editor.get_parent().get_parent()
	var editor_index: int = _script_editor.get_open_script_editors().find(text_editor)
	# sooo, sorry
	var editor_layout = ConfigFile.new()
	editor_layout.load("res://.godot/editor/editor_layout.cfg")
	var open_scripts: Array = editor_layout.get_value("ScriptEditor", "open_scripts")

	var file_path = open_scripts.get(editor_index)

	_open_files[file_path] = dialogue_editor


func has_open_editor_for_file(file_path: String) -> bool:
	return _open_files.has(file_path) and is_instance_valid(_open_files[file_path])


func get_editor_for_file(file_path: String) -> DialogueEditorDecorator:
	return _open_files[file_path]


func open_file(file_path: String) -> void:
	EditorInterface.edit_resource(load(file_path))


func generate_line_ids(file_path: String) -> void:
	if has_open_editor_for_file(file_path):
		get_editor_for_file(file_path).generate_line_ids()
