extends SyntaxHighlighter

const HighlighterCore = preload("res://addons/clyde/editor/syntax/highlighter_core.gd")

var _core: HighlighterCore = HighlighterCore.new()

func _clear_highlighting_cache():
	_core.clear_highlighting_cache()


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var editor: TextEdit = get_text_edit()
	return _core.get_line_syntax_highlighting(editor, editor.editor_theme_config, line)
