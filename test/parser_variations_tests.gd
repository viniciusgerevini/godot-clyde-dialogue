extends './test.gd'

const Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)


func _test_simple_variations():
	var result = parse("""
(
	- yes
	- no
)
""")

	var expected = {
		"type": 'document',
		"blocks": [],
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'variations', "mode": 'sequence', "content": [
						{ "type": 'content', "content": [ { "type": 'line', "value": 'yes' }, ], },
						{ "type": 'content', "content": [ { "type": 'line', "value": 'no' }, ], },
				],},
			],
		},
		],
	}

	expect(result, expected)


func _test_simple_variations_with_no_indentation():
	var result = parse("""
(
- yes
- no
)
""")

	var expected = {
		"type": 'document',
		"blocks": [],
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'variations', "mode": 'sequence', "content": [
						{ "type": 'content', "content": [ { "type": 'line', "value": 'yes' }, ], },
						{ "type": 'content', "content": [ { "type": 'line', "value": 'no' }, ], },
				],},
			],
		},
		],
	}

	expect(result, expected)


func _test_nested_variations():
	var result = parse("""
(
	- yes
	- no
	- (
		- nested 1
	)
)
""")

	var expected = {
		"type": 'document',
		"blocks": [],
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'variations', "mode": 'sequence', "content": [
						{ "type": 'content', "content": [ { "type": 'line', "value": 'yes' }, ], },
						{ "type": 'content', "content": [ { "type": 'line', "value": 'no' }, ], },
						{ "type": 'content', "content": [
							{ "type": 'variations', "mode": 'sequence', "content": [
									{ "type": 'content', "content": [ { "type": 'line', "value": 'nested 1' }, ], },
							],},
						], },
				],},
			],
		},
		],
	}

	expect(result, expected)


func _test_variations_modes():
	for mode in ['shuffle', 'shuffle once', 'shuffle cycle', 'shuffle sequence', 'sequence', 'once', 'cycle']:
		_mode_test(mode)

func _mode_test(mode):
	var result = parse("""
( %s
	- yes
	- no
)
""" % mode)

	var expected = {
		"type": 'document',
		"blocks": [],
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'variations', "mode": mode, "content": [
						{ "type": 'content', "content": [ { "type": 'line', "value": 'yes' }, ], },
						{ "type": 'content', "content": [ { "type": 'line', "value": 'no' }, ], },
				],},
			],
		},
		],
	}

	expect(result, expected)


func _test_variations_with_options():
	var result = parse("""
(
- * works?
		yes
	* [yep?]
		yes
- nice
-
	* works?
		yes
	* [yep?]
		yes
)
""")

	var expected = {
		"type": 'document',
		"blocks": [],
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'variations', "mode": 'sequence', "content": [
					{ "type": 'content', "content": [
						{ "type": 'options', "content": [
							{ "type": 'option', "name": 'works?', "mode": 'once', "content": {
									"type": 'content', "content": [ { "type": 'line', "value": 'works?' }, { "type": 'line', "value": 'yes' }, ],
								},
							},
							{ "type": 'option', "name": 'yep?', "mode": 'once', "content": { "type": 'content', "content": [ { "type": 'line', "value": 'yes' }, ], }, },
						]},
					], },
					{ "type": 'content', "content": [ { "type": 'line', "value": 'nice' }, ], },
					{ "type": 'content', "content": [
						{ "type": 'options', "content": [
							{ "type": 'option', "name": 'works?', "mode": 'once', "content": {
									"type": 'content', "content": [ { "type": 'line', "value": 'works?' }, { "type": 'line', "value": 'yes' }, ],
								},
							},
							{ "type": 'option', "name": 'yep?', "mode": 'once', "content": { "type": 'content', "content": [ { "type": 'line', "value": 'yes' }, ], }, },
						]},
					], },
				],},
			],
		},
		],
	}

	expect(result, expected)
