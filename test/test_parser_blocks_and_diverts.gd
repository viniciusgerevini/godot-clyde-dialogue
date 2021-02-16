extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)

func test_parse_blocks():
	var result = parse("""
== first block
line 1
line 2

== second_block
line 3
line 4

""")
	var expected = {
		"type": 'document',
		"content": [],
		"blocks": [
			{ "type": 'block', "name": 'first block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 1', "speaker": null, "id": null, "tags": null, },
					{ "type": 'line', "value": 'line 2', "speaker": null, "id": null, "tags": null, },
				]
			}},
			{ "type": 'block', "name": 'second_block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 3', "speaker": null, "id": null, "tags": null, },
					{ "type": 'line', "value": 'line 4', "speaker": null, "id": null, "tags": null, },
				]
			}},
		]
	}
	assert_eq_deep(result, expected)

func test_parse_blocks_and_lines():
	var result = parse("""
line outside block 1
line outside block 2

== first block
line 1
line 2

== second_block
line 3
line 4

""")
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'line outside block 1', "speaker": null, "id": null, "tags": null, },
				{ "type": 'line', "value": 'line outside block 2', "speaker": null, "id": null, "tags": null, },
			]
		}],
		"blocks": [
			{ "type": 'block', "name": 'first block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 1', "speaker": null, "id": null, "tags": null, },
					{ "type": 'line', "value": 'line 2', "speaker": null, "id": null, "tags": null, },
				]
			}},
			{ "type": 'block', "name": 'second_block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 3', "speaker": null, "id": null, "tags": null, },
					{ "type": 'line', "value": 'line 4', "speaker": null, "id": null, "tags": null, },
				]
			}},
		]
	}
	assert_eq_deep(result, expected)


func test_parse_diverts():
	var result = parse("""
-> one
-> END
<-
* [thats it]
	-> somewhere
	<-
* [ does it work this way? ]
	-> go
""")
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'divert', "target": 'one' },
				{ "type": 'divert', "target": '<end>' },
				{ "type": 'divert', "target": '<parent>' },
				{ "type": 'options', "speaker": null, "id": null, "tags": null, "name": null, "content": [
						{ "type": 'option', "name": 'thats it', "mode": 'once', "speaker": null, "id": null, "tags": null, "content": {
								"type": 'content',
								"content": [
									{ "type": 'divert', "target": 'somewhere' },
									{ "type": 'divert', "target": '<parent>' },
								],
						}},
						{ "type": 'option', "name": 'does it work this way?', "mode": 'once', "speaker": null, "id": null, "tags": null, "content": {
								"type": 'content',
								"content": [
									{ "type": 'divert', "target": 'go' },
								],
						}},
				]},
			]
		}],
		"blocks": []
	}
	assert_eq_deep(result, expected)


func test_parse_empty_block():
	var result = parse("""
== first block
""")
	var expected = {
		"type": 'document',
		"content": [],
		"blocks": [
			{ "type": 'block', "name": 'first block', "content": {
				"type": 'content',
				"content": []
			}},
		]
	}
	assert_eq_deep(result, expected)
