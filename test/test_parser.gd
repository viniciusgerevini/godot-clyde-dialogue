extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func test_parse_empty_document():
	var parser = Parser.new()
	var result = parser.parse('');
	var expected = {
		"type": 'document',
		"content": [],
		"blocks": []
	};
	assert_eq_deep(result, expected);


func test_parse_document_with_multiple_line_breaks():
	var parser = Parser.new()
	var result = parser.parse('\n\n\n\n\n\n\n\n\n\n\n\n\n\n')
	var expected = {
		"type": 'document',
		"content": [],
		"blocks": []
	};
	assert_eq_deep(result, expected);
