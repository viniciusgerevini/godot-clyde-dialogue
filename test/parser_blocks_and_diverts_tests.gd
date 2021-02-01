extends './test.gd'

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)

func _test_parse_blocks():
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
					{ "type": 'line', "value": 'line 1' },
					{ "type": 'line', "value": 'line 2' },
				]
			}},
			{ "type": 'block', "name": 'second_block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 3' },
					{ "type": 'line', "value": 'line 4' },
				]
			}},
		]
	}
	expect(result, expected)

func _test_parse_blocks_and_lines():
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
				{ "type": 'line', "value": 'line outside block 1' },
				{ "type": 'line', "value": 'line outside block 2' },
			]
		}],
		"blocks": [
			{ "type": 'block', "name": 'first block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 1' },
					{ "type": 'line', "value": 'line 2' },
				]
			}},
			{ "type": 'block', "name": 'second_block', "content": {
				"type": 'content',
				"content": [
					{ "type": 'line', "value": 'line 3' },
					{ "type": 'line', "value": 'line 4' },
				]
			}},
		]
	}
	expect(result, expected)


func _test_parse_diverts():
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
				{ "type": 'options', "content": [
						{ "type": 'option', "name": 'thats it', "mode": 'once', "content": {
								"type": 'content',
								"content": [
									{ "type": 'divert', "target": 'somewhere' },
									{ "type": 'divert', "target": '<parent>' },
								],
						}},
						{ "type": 'option', "name": 'does it work this way?', "mode": 'once', "content": {
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
	expect(result, expected)


func _test_parse_empty_block():
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
	expect(result, expected)
