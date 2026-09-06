@tool
class_name ClydeEditorSyntaxHighlighter extends EditorSyntaxHighlighter

signal new_highlighter_instantiated(editor: CodeEdit)

const ClydeEditorSettings = preload("../config/settings.gd")
const HighlighterCore = preload("./highlighter_core.gd")

var _core: HighlighterCore = HighlighterCore.new()

static var settings: ClydeEditorSettings

func _create() -> EditorSyntaxHighlighter:
	var h = ClydeEditorSyntaxHighlighter.new()
	# There is no reliable way to be notified a text file was opened in godot's script
	# editor. This is a hacky solution that relies on the usage of the highlighter.
	# This method is called deferred so the editor is attached to it by the time the
	# event is triggered.
	self.call_deferred("_notify_new_highlighter", h)
	return h


func _notify_new_highlighter(h: ClydeEditorSyntaxHighlighter) -> void:
	var editor: CodeEdit = h.get_text_edit()
	if editor != null:
		new_highlighter_instantiated.emit(editor)


func _get_name() -> String:
	return "Clyde Dialogue"


func _get_supported_languages() -> PackedStringArray:
	return ["clyde", "TextFile"]


func _clear_highlighting_cache():
	_core.clear_highlighting_cache()


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var editor: TextEdit = get_text_edit()

	var config = {
		"color_scheme": settings.editor_color_scheme()
	}
	return _core.get_line_syntax_highlighting(editor, config, line)
