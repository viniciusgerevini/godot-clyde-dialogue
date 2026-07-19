@tool
extends EditorSyntaxHighlighter

const ClydeEditorSettings = preload("../config/settings.gd")
const HighlighterCore = preload("./highlighter_core.gd")

var _core: HighlighterCore = HighlighterCore.new()

static var settings: ClydeEditorSettings

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
