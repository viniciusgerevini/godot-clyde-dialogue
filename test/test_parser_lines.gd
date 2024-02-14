extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)


func test_parse_single_line():
	var result = parse('jules: say what one more time! $first #yelling #mad')
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [{
				"type": 'line',
				"value": 'say what one more time!',
				"id": 'first',
				"speaker": 'jules',
				"tags": [
					'yelling',
					'mad'
				],
				"id_suffixes": null,
			}]
		}],
		"blocks": []
	}
	assert_eq_deep(result, expected)


func test_parse_lines():
		var result = parse("""
jules: say what one more time! $first #yelling #mad
just text
just id $another&var1&var2
just tags #tag
speaker: just speaker
id last #tag #another_tag $some_id
""")

		var expected = {
			"type": 'document',
			"content": [{
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'say what one more time!', "id": 'first', "speaker": 'jules', "tags": [ 'yelling', 'mad' ], "id_suffixes": null },
					{ "type": 'line', "value": 'just text', "speaker": null, "id": null, "tags": [], "id_suffixes": null },
					{ "type": 'line', "value": 'just id', "id": 'another', "speaker": null, "tags": [], "id_suffixes": [ "var1", "var2" ] },
					{ "type": 'line', "value": 'just tags', "tags": [ 'tag' ], "speaker": null, "id": null, "id_suffixes": null },
					{ "type": 'line', "value": 'just speaker', "speaker": 'speaker', "id": null, "tags": [], "id_suffixes": null },
					{ "type": 'line', "value": 'id last', "speaker": null, "id": 'some_id', "tags": [ 'tag', 'another_tag' ], "id_suffixes": null },
				]
			}],
			"blocks": []
		}

		assert_eq_deep(result, expected)


func test_parse_multiline():
	var result = parse("""
jules: say what one more time!
	 Just say it $some_id #tag
hello! $id_on_first_line #and_tags
	Just talking.
""")
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'say what one more time! Just say it', "id": 'some_id', "speaker": 'jules', "tags": [ 'tag' ], "id_suffixes": null },
				{ "type": 'line', "value": 'hello! Just talking.', "id": 'id_on_first_line', "tags": [ 'and_tags' ], "speaker": null, "id_suffixes": null },
			]
		}],
		"blocks": []
	}
	assert_eq_deep(result, expected)


func test_parse_text_in_quotes():
	var result = parse("""
\"jules: say what one more time!
	 Just say it $some_id #tag\"
\"hello! $id_on_first_line #and_tags
Just talking.\"

\"this has $everything:\" $id_on_first_line #and_tags
""")
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'jules: say what one more time!\n	 Just say it $some_id #tag', "speaker": null, "id": null, "tags": [], "id_suffixes": null },
				{ "type": 'line', "value": 'hello! $id_on_first_line #and_tags\nJust talking.', "speaker": null, "id": null, "tags": [], "id_suffixes": null },
				{ "type": 'line', "value": 'this has $everything:', "id": 'id_on_first_line', "tags": [ 'and_tags' ], "speaker": null, "id_suffixes": null },
			]
		}],
		"blocks": []
	}
	assert_eq_deep(result, expected)


func test_parser_with_meta():
	var parser = Parser.new()
	var result = parser.parse("""
jules: say what one more time!
	Just say it $some_id #tag
*= this is an option
this is a nested option
	*= this is an option

== this is a block
""", true)
	assert_eq_deep(result.content[0].content[0].meta, {  "line": 1, "column": 7 })
	assert_eq_deep(result.content[0].content[1].meta, { "line": 3, "column": 0 })
	assert_eq_deep(result.content[0].content[2].meta, { "line": 4, "column": 0 })
	assert_eq_deep(result.blocks[0].meta, { "line": 7, "column": 0 })
