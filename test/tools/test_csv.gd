extends "res://addons/gut/test.gd"

const Settings = preload("res://addons/clyde/editor/config/settings.gd")
const Parser = preload("res://addons/clyde/parser/Parser.gd")
const TestSettings = preload("res://test/helpers/test_editor_settings.gd")

const Csv = preload("res://addons/clyde/editor/tools/csv.gd")

var _settings: Settings
var _csv: Csv

const TEST_CSV_FILE_PATH = "user://test.csv"

func _parse(input: String) -> Dictionary:
	var p = Parser.new()
	return p.parse(input)


func _run_create_csv_expecting_success(input: String) -> void:
	var dialogue = _parse(input)
	var result = _csv.create_csv_file(TEST_CSV_FILE_PATH, dialogue)
	assert_true(result, "Result should be true")


func _read_test_csv() -> String:
	var file = FileAccess.open(TEST_CSV_FILE_PATH, FileAccess.READ)
	return file.get_as_text()


func _assert_test_csv(lines: Array[String]) -> void:
	assert_eq(_read_test_csv(), "%s\n" % "\n".join(lines))



func before_each():
	var test_settings = TestSettings.new()
	_settings = Settings.new(test_settings)
	_csv = Csv.new(_settings)


func test_creates_csv_file() -> void:
	_run_create_csv_expecting_success("test $abc")

	_assert_test_csv([
		"id,en",
		"abc,test",
	])


func test_does_not_include_header_when_option_is_false() -> void:
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_HEADER, false)

	_run_create_csv_expecting_success("test $abc")

	_assert_test_csv([
		"abc,test",
	])


func test_includes_header_when_option_is_true() -> void:
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_HEADER, true)

	_run_create_csv_expecting_success("test $abc")

	_assert_test_csv([
		"id,en",
		"abc,test",
	])


func test_excludes_lines_without_ids() -> void:
	_run_create_csv_expecting_success("""
First line $id_1
This line should not be included
Third line $id_2
""")

	_assert_test_csv([
		"id,en",
		"id_1,First line",
		"id_2,Third line",
	])


func test_sets_locale_in_header() -> void:
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_HEADER_LOCALE, "pt")

	_run_create_csv_expecting_success("test $id_1")

	_assert_test_csv([
		"id,pt",
		"id_1,test",
	])


func test_uses_custom_delimiter() -> void:
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_DELIMITER, ";")

	_run_create_csv_expecting_success("test $id_1")

	_assert_test_csv([
		"id;en",
		"id_1;test",
	])


func test_includes_speaker_and_tags_as_metadata() -> void:
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_METADATA, true)

	_run_create_csv_expecting_success("vini: testing $id_1 #banana #apple")

	_assert_test_csv([
		"id,en,metadata",
		"id_1,testing,speaker: vini tags: banana apple",
	])


func test_automatically_includes_quotes_when_needed() -> void:
	_run_create_csv_expecting_success("""
this line has , which is the reserved delimiter $id_1
this line is fine $id_2
""")

	_assert_test_csv([
		"id,en",
		'id_1,"this line has , which is the reserved delimiter"',
		'id_2,this line is fine',
	])


func test_automatically_includes_quotes_when_needed_with_custom_delimiter() -> void:
	_settings.set_project_config(_settings.CSV_EXPORTER_CFG_DELIMITER, ";")

	_run_create_csv_expecting_success("""
this line has ; which is the reserved delimiter $id_1
this line is , fine $id_2
""")

	_assert_test_csv([
		"id;en",
		'id_1;"this line has ; which is the reserved delimiter"',
		'id_2;this line is , fine',
	])


func test_works_with_complex_dialogue() -> void:
	_run_create_csv_expecting_success("""
Let's test this dialogue $id_1
What do you think? $id_2
	* that's ok $id_3
		alright
	* that's not ok $id_4
		oh no!
Some variations $id_5
(
	- hello $id_6
	- hi $id_7
	- hi again $id_8
)
{ is_true } conditional $id_9
{ trigger event_1 } with action $id_10
""")

	_assert_test_csv([
		"id,en",
		"id_1,Let's test this dialogue",
		"id_2,What do you think?",
		"id_3,that's ok",
		"id_4,that's not ok",
		"id_5,Some variations",
		"id_6,hello",
		"id_7,hi",
		"id_8,hi again",
		"id_9,conditional",
		"id_10,with action",
	])
