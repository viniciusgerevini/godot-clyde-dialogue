extends './test.gd'

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)


func _test_parse_options():
	var result = parse("""
npc: what do you want to talk about?
* speaker: Life
	player: I want to talk about life!
	npc: Well! That's too complicated...
* Everything else... #some_tag
	player: What about everything else?
	npc: I don't have time for this...
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', },
				{
					"type": 'options',
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"speaker": 'speaker',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Life', "speaker": 'speaker' },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Everything else...', "tags": [ 'some_tag', ] },
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', },
									{ "type": 'line', "value": 'I don\'t have time for this...', "speaker": 'npc', },
								],
							},
							"tags": [ 'some_tag', ],
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)


func _test_parse_sticky_option():
	var result = parse("""
npc: what do you want to talk about?
* Life
	player: I want to talk about life!
+ Everything else... #some_tag
	player: What about everything else?
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', },
				{
					"type": 'options',
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Life' },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'sticky',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Everything else...', "tags": [ 'some_tag', ] },
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', },
								],
							},
							"tags": [ 'some_tag', ],
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)


func _test_define_label_only_text():
	var result = parse("""
npc: what do you want to talk about?
* [Life]
	player: I want to talk about life!
	npc: Well! That's too complicated...
* [Everything else... #some_tag]
	player: What about everything else?
	npc: I don't have time for this...
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', },
				{
					"type": 'options',
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', },
									{ "type": 'line', "value": 'I don\'t have time for this...', "speaker": 'npc', },
								],
							},
							"tags": [ 'some_tag', ],
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)

func _test_use_first_line_as_label():
	var result = parse("""
*
	life
	player: I want to talk about life!
	npc: Well! That's too complicated...

""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'life' },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', },
								],
							},
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)


func _test_use_previous_line_as_label():
	var result = parse("""
spk: this line will be the label $some_id #some_tag
	* life
		player: I want to talk about life!
		npc: Well! That's too complicated...

spk: second try
	* life
		npc: Well! That's too complicated...
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"speaker": 'spk',
					"id": 'some_id',
					"tags": ['some_tag'],
					"name": 'this line will be the label',
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'life' },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', },
								],
							},
						},
					],
				},
				{
					"type": 'options',
					"speaker": 'spk',
					"name": 'second try',
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'life' },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', },
								],
							},
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)

func _test_use_previous_line_in_quotes_as_label():
	var result = parse("""
\"spk: this line will be the label $some_id #some_tag\"
	* life
		player: I want to talk about life!


\"spk: this line will be the label $some_id #some_tag\"
	* universe
		player: I want to talk about the universe!
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"name": 'spk: this line will be the label $some_id #some_tag',
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'life' },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', },
								],
							},
						},
					],
				},
				{
					"type": 'options',
					"name": 'spk: this line will be the label $some_id #some_tag',
					"content": [
						{
							"type": 'option',
							"name": 'universe',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'universe' },
									{ "type": 'line', "value": 'I want to talk about the universe!', "speaker": 'player', },
								],
							},
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)


func _test_ensures_options_ending_worked():
	var result = parse("""
* yes
* no

{ some_check } maybe
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"content": [
						{
							"type": 'option',
							"name": 'yes',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'yes' },
								],
							},
						},
						{
							"type": 'option',
							"name": 'no',
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'no' },
								],
							},
						},
					],
				},
				{
					"type": "conditional_content",
					"conditions": { "type": "variable", "name": "some_check" },
					"content": { "type": "line", "value": "maybe", }
				},
			],
		},
		],
		"blocks": [],
	}
	expect(result, expected)


func _test_ensures_option_item_ending_worked():
	var result = parse("""
* yes { set yes = true }
* [no]
	no
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"content": [
						{
							"type": "action_content",
							"action": {
								"type": 'assignments',
								"assignments": [
									{
										"type": 'assignment',
										"variable": { "type": 'variable', "name": 'yes', },
										"operation": 'assign',
										"value": { "type": 'literal', "name": 'boolean', "value": true, },
									},
								],
							},
							"content": {
								"type": 'option',
								"name": 'yes',
								"mode": 'once',
								"content": { "type": 'content', "content": [{ "type": 'line', "value": 'yes' }]},
							},
						},
						{
							"type": 'option',
							"name": 'no',
							"mode": 'once',
							"content": { "type": 'content', "content": [ { "type": 'line', "value": 'no' }, ]},
						},
					],
				},
			],
		}],
		"blocks": [],
	}
	expect(result, expected)


func _test_options_with_blocks_both_sides():
	var result = parse("""
* { what } yes { set yes = true }
* {set no = true} [no] { when something }
	no
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"content": [
						{
						 "type": "conditional_content",
						 "conditions": { "type": "variable", "name": "what" },
						 "content": {
								"type": "action_content",
								"action": {
									"type": 'assignments',
									"assignments": [
										{
											"type": 'assignment',
											"variable": { "type": 'variable', "name": 'yes', },
											"operation": 'assign',
											"value": { "type": 'literal', "name": 'boolean', "value": true, },
										},
									],
								},
								"content": {
									"type": 'option',
									"name": 'yes',
									"mode": 'once',
									"content": { "type": 'content', "content": [{ "type": 'line', "value": 'yes' }]},
								},
							},
					 },

						{
							"type": "action_content",
							"action": {
								"type": 'assignments',
								"assignments": [
									{
										"type": 'assignment',
										"variable": { "type": 'variable', "name": 'no', },
										"operation": 'assign',
										"value": { "type": 'literal', "name": 'boolean', "value": true, },
									},
								],
							},
							"content": {
								"type": "conditional_content",
								"conditions": { "type": "variable", "name": "something" },
								"content": {
									"type": 'option',
									"name": 'no',
									"mode": 'once',
									"content": { "type": 'content', "content": [ { "type": 'line', "value": 'no' }, ]},
								},
							},
						},
					],
				},
			],
		}],
		"blocks": [],
	}
	expect(result, expected)
