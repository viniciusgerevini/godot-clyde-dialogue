extends RefCounted

signal settings_changed

const ClydeEditorSettings = preload("./editor_settings/clyde_editor_settings.gd")

var _editor_settings: ClydeEditorSettings

const EDITOR_CFG_SHOW_LISTS = "show_lists"
const EDITOR_CFG_SHOW_PLAYER = "show_player"
const EDITOR_CFG_SYNC_PLAYER = "sync_player"
const EDITOR_CFG_PLAYER_SHOW_MULTI_BUBBLE = "player_multi_bubble"
const EDITOR_CFG_PLAYER_SHOW_METADATA = "player_metadata"
const EDITOR_CFG_EDITOR_FOLLOW_EXECUTION = "follow_execution"


const CSV_EXPORTER_CFG_INCLUDE_METADATA = "csv_include_metadata"
const CSV_EXPORTER_CFG_ALWAYS_USE_QUOTES = "csv_use_quotes"
const CSV_EXPORTER_CFG_INCLUDE_HEADER = "csv_include_header"
const CSV_EXPORTER_CFG_HEADER_LOCALE = "csv_header_locale"
const CSV_EXPORTER_CFG_DELIMITER = "csv_delimiter"
const CSV_EXPORTER_CFG_QUOTE_TYPE = "csv_quote_type"
const CSV_EXPORTER_RECORDED_PATHS = "csv_recorded_paths"

const ONLINE_DOCS_URL = "https://thisisvini.com/clyde"
const REPORT_ISSUE_URL = "https://github.com/viniciusgerevini/godot-clyde-dialogue/issues"

const COLORSCHEME: Array[String] = [
	"background",
	"current_line",
	"error_line",
	"comment",
	"identifier",
	"symbol",
	"text",
	"tag",
	"keyword",
	"operator",
	"number_literal",
	"boolean_literal",
	"string_literal",
	"warning_color",
	"success_color",
	"error_color",
]

const BASE_SETTINGS: Array[String] = [
	"auto_brace_completion_enabled",
	"auto_brace_completion_highlight_matching",
	"code_completion_enabled",
	"gutters_draw_line_numbers",
	"gutters_zero_pad_line_numbers",
	"show_line_length_guidelines",
	"line_length_guideline_hard_column",
	"line_length_guideline_soft_column",
	"indent_automatic",
	"indent_size",
	"indent_use_spaces",
	"autowrap_mode",
	"caret_blink",
	"caret_blink_interval",
	"caret_type",
	"drag_and_drop_selection_enabled",
	"draw_spaces",
	"draw_tabs",
	"highlight_current_line",
	"minimap_draw",
	"minimap_width",
	"scroll_past_end_of_file",
	"scroll_smooth",
	"scroll_v_scroll_speed",
	"wrap_mode",
	"font_size",
]

func _init(editor_settings: ClydeEditorSettings):
	_editor_settings = editor_settings
	_editor_settings.settings_changed.connect(_on_settings_changed)


func _get_editor_setting(key: String):
	return _editor_settings.get_setting(key)


func change_font_size(offset: float):
	_editor_settings.change_font_size(offset)


func clear_font_size():
	_editor_settings.clear_font_size()


func editor_settings() -> Dictionary[String, Variant]:
	var dictionary: Dictionary[String, Variant] = {}

	for c in BASE_SETTINGS:
		dictionary[c] = _editor_settings.get_setting(c)

	if typeof(dictionary["indent_use_spaces"]) == TYPE_INT:
		# This is an enum in Editor settings. Couldn't find the right type so comparing agains the int value
		dictionary["indent_use_spaces"] = dictionary["indent_use_spaces"] == 1

	if dictionary["show_line_length_guidelines"]:
		dictionary["line_length_guidelines"] = [
			dictionary["line_length_guideline_hard_column"],
			dictionary["line_length_guideline_soft_column"],
		]
	else:
		dictionary["line_length_guidelines"] = []

	dictionary["font_size"] = dictionary["font_size"] * _editor_settings.get_interface_scale()

	return dictionary


func editor_color_scheme() -> Dictionary[String, Color]:
	var dictionary: Dictionary[String, Color] = {}

	for c in COLORSCHEME:
		dictionary[c] = _editor_settings.get_color_scheme_setting(c)

	return dictionary


func get_theme_accent_color() -> Color:
	return Color(_editor_settings.get_interface_setting("accent_color"))


func get_theme_base_color() -> Color:
	return Color(_editor_settings.get_interface_setting("base_color"))


func _on_settings_changed():
	settings_changed.emit()


func get_editor_config():
	return _editor_settings.get_project_metadata("clyde", "config", {})


func get_config(config_name: String, value: Variant) -> Variant:
	var config = get_editor_config()
	return config.get(config_name, value)


func set_config(config_name: String, value: Variant) -> void:
	var config = get_editor_config()
	config[config_name] = value
	_editor_settings.set_project_metadata("clyde", "config", config)


func get_open_files():
	return _editor_settings.get_project_metadata("clyde", "open_files", [])


func set_open_files(open_files: Array):
	_editor_settings.set_project_metadata("clyde", "open_files", open_files)


func get_recents() -> Array:
	return _editor_settings.get_project_metadata("clyde", "recents", [])


func set_recents(recents: Array):
	_editor_settings.set_project_metadata("clyde", "recents", recents)


func add_recent(path: String):
	var recents = get_recents()
	if recents.has(path):
		recents.erase(path)
	elif recents.size() > 9:
		recents.remove_at(9)
	recents.push_front(path)
	set_recents(recents)


func clear_recents():
	set_recents([])


func get_project_config(config_key: String, default):
	return _editor_settings.get_project_metadata("clyde", config_key, default)


func set_project_config(config_key: String, value):
	_editor_settings.set_project_metadata("clyde", config_key, value)


func get_external_variables() -> Dictionary:
	return _editor_settings.get_project_metadata("clyde", "ext_variables", {})


func set_external_variables(variables: Dictionary) -> void:
	_editor_settings.set_project_metadata("clyde", "ext_variables", variables)
