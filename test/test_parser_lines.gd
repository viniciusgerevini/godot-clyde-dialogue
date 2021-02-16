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
				]
			}]
		}],
		"blocks": []
	}
	assert_eq_deep(result, expected)


func test_parse_lines():
		var result = parse("""
jules: say what one more time! $first #yelling #mad
just text
just id $another
just tags #tag
speaker: just speaker
id last #tag #another_tag $some_id
""")

		var expected = {
			"type": 'document',
			"content": [{
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'say what one more time!', "id": 'first', "speaker": 'jules', "tags": [ 'yelling', 'mad' ] },
					{ "type": 'line', "value": 'just text', "speaker": null, "id": null, "tags": null, },
					{ "type": 'line', "value": 'just id', "id": 'another', "speaker": null, "tags": null, },
					{ "type": 'line', "value": 'just tags', "tags": [ 'tag' ], "speaker": null, "id": null },
					{ "type": 'line', "value": 'just speaker', "speaker": 'speaker', "id": null, "tags": null, },
					{ "type": 'line', "value": 'id last', "speaker": null, "id": 'some_id', "tags": [ 'tag', 'another_tag' ] },
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
				{ "type": 'line', "value": 'say what one more time! Just say it', "id": 'some_id', "speaker": 'jules', "tags": [ 'tag' ] },
				{ "type": 'line', "value": 'hello! Just talking.', "id": 'id_on_first_line', "tags": [ 'and_tags' ], "speaker": null, },
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
				{ "type": 'line', "value": 'jules: say what one more time!\n	 Just say it $some_id #tag', "speaker": null, "id": null, "tags": null,  },
				{ "type": 'line', "value": 'hello! $id_on_first_line #and_tags\nJust talking.', "speaker": null, "id": null, "tags": null,  },
				{ "type": 'line', "value": 'this has $everything:', "id": 'id_on_first_line', "tags": [ 'and_tags' ], "speaker": null, },
			]
		}],
		"blocks": []
	}
	assert_eq_deep(result, expected)
