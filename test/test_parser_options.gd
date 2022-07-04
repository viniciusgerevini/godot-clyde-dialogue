extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)


func test_parse_options():
	var result = parse("""
npc: what do you want to talk about?
* speaker: Life
	player: I want to talk about life!
	npc: Well! That's too complicated...
* Everything else... #some_tag
	player: What about everything else?
	npc: I don't have time for this...
* one more thing $abc&whatever
	npc: one
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"speaker": 'speaker',
							"id": null,
							"tags": null,
							"id_suffixes": null,
							"mode": 'once',
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'once',
							"speaker": null,
							"id": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'I don\'t have time for this...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
							"tags": [ 'some_tag', ],
							"id_suffixes": null,
						},
						{
							"type": "option",
							"name": "one more thing",
							"mode": "once",
							"speaker": null,
							"tags": null,
							"content": {
								"type": "content",
								"content": [
										{ "type": "line", "value": "one", "speaker": "npc","tags": null, "id": null, "id_suffixes": null, },
									],
								},
							"id": "abc",
							"id_suffixes": [ "whatever" ],
							},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	assert_eq_deep(result, expected)


func test_parse_sticky_option():
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
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"mode": 'once',
							"speaker": null,
							"id": null,
							"tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'sticky',
							"speaker": null,
							"id": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
							"tags": [ 'some_tag', ],
							"id_suffixes": null,
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	assert_eq_deep(result, expected)


func test_parse_fallback_option():
	var result = parse("""
npc: what do you want to talk about?
* Life
	player: I want to talk about life!
> Everything else... #some_tag
	player: What about everything else?
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"mode": 'once',
							"speaker": null,
							"id": null,
							"tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'fallback',
							"speaker": null,
							"id": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
							"tags": [ 'some_tag', ],
							"id_suffixes": null,
						},
					],
				},
			],
		},
		],
		"blocks": [],
	}
	assert_eq_deep(result, expected)



func test_define_label_to_display_as_content():
	var result = parse("""
npc: what do you want to talk about?
*= Life
	player: I want to talk about life!
	npc: Well! That's too complicated...
*= Everything else... #some_tag
	player: What about everything else?
	npc: I don't have time for this...
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{ "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'Life',
							"mode": 'once',
							"id": null, "tags": null, "speaker": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Life', "speaker": null, "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
						{
							"type": 'option',
							"name": 'Everything else...',
							"mode": 'once', "id": null, "speaker": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Everything else...', "speaker": null, "id": null, "tags": [ 'some_tag', ], "id_suffixes": null, },
									{ "type": 'line', "value": 'What about everything else?', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'I don\'t have time for this...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
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
	assert_eq_deep(result, expected)

func test_use_first_line_as_label():
	var result = parse("""
*
	life
	player: I want to talk about life!
	npc: Well! That's too complicated...
*
	the universe #tag $id&suffix
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once', "id": null, "tags": null, "speaker": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'life', "id": null, "speaker": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
						{
							"type": 'option',
							"name": 'the universe',
							"mode": 'once', "id": "id", "tags": ["tag"], "speaker": null,
							"id_suffixes": ["suffix"],
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": "the universe", "id": "id", "speaker": null, "tags": ["tag"], "id_suffixes": ["suffix"], },
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
	assert_eq_deep(result, expected)


func test_use_previous_line_as_label():
	var result = parse("""
spk: this line will be the label $some_id&some_suffix #some_tag
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
					"id_suffixes": ["some_suffix"],
					"name": 'this line will be the label',
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once', "id": null, "speaker": null, "tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
					],
				},
				{
					"type": 'options',
					"speaker": 'spk',
					"name": 'second try',
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once', "id": null, "speaker": null, "tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'Well! That\'s too complicated...', "speaker": 'npc', "id": null, "tags": null, "id_suffixes": null, },
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
	assert_eq_deep(result, expected)

func test_use_previous_line_in_quotes_as_label():
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
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"name": 'spk: this line will be the label $some_id #some_tag',
					"content": [
						{
							"type": 'option',
							"name": 'life',
							"mode": 'once', "id": null, "tags": null, "speaker": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about life!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
					],
				},
				{
					"type": 'options',
					"name": 'spk: this line will be the label $some_id #some_tag',
					"tags": null,
					"id_suffixes": null,
					"speaker": null,
					"id": null,
					"content": [
						{
							"type": 'option',
							"name": 'universe',
							"mode": 'once', "id": null, "speaker": null, "tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'I want to talk about the universe!', "speaker": 'player', "id": null, "tags": null, "id_suffixes": null, },
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
	assert_eq_deep(result, expected)


func test_ensures_options_ending_worked():
	var result = parse("""
*= yes
*= no

{ some_check } maybe
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
					"content": [
						{
							"type": 'option',
							"name": 'yes',
							"mode": 'once',
							"id": null, "speaker": null, "tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'yes', "id": null, "speaker": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
						{
							"type": 'option',
							"name": 'no',
							"mode": 'once',
							"id": null, "speaker": null, "tags": null,
							"id_suffixes": null,
							"content": {
								"type": 'content',
								"content": [
									{ "type": 'line', "value": 'no', "id": null, "speaker": null, "tags": null, "id_suffixes": null, },
								],
							},
						},
					],
				},
				{
					"type": "conditional_content",
					"conditions": { "type": "variable", "name": "some_check" },
					"content": { "type": "line", "value": "maybe", "id": null, "speaker": null, "tags": null, "id_suffixes": null, }
				},
			],
		},
		],
		"blocks": [],
	}
	assert_eq_deep(result, expected)


func test_ensures_option_item_ending_worked():
	var result = parse("""
*= yes { set yes = true }
* no
	no
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
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
								"mode": 'once', "id": null, "speaker": null, "tags": null, "id_suffixes": null,
								"content": { "type": 'content', "content": [{ "type": 'line', "value": 'yes', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }]},
							},
						},
						{
							"type": 'option',
							"name": 'no',
							"mode": 'once', "id": null, "speaker": null, "tags": null, "id_suffixes": null,
							"content": { "type": 'content', "content": [ { "type": 'line', "value": 'no' , "id": null, "speaker": null, "tags": null, "id_suffixes": null, }, ]},
						},
					],
				},
			],
		}],
		"blocks": [],
	}
	assert_eq_deep(result, expected)


func test_options_with_blocks_both_sides():
	var result = parse("""
*= { what } yes { set yes = true }
* {set no = true} no { when something }
	no
""" )
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
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
									"mode": 'once', "id": null, "speaker": null, "tags": null,
									"id_suffixes": null,
									"content": { "type": 'content', "content": [{ "type": 'line', "value": 'yes', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }]},
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
									"mode": 'once', "id": null, "speaker": null, "tags": null,
									"id_suffixes": null,
									"content": { "type": 'content', "content": [ { "type": 'line', "value": 'no', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }, ]},
								},
							},
						},
					],
				},
			],
		}],
		"blocks": [],
	}
	assert_eq_deep(result, expected)


func test_options_with_multiple_blocks_on_same_side():
	var result = parse("""
*= yes { when what } { set yes = true }
*= no {set no = true} { when something }
*= { when what } { set yes = true } yes
*= {set no = true} { when something } no
*= {set yes = true} { when yes } yes { set one_more = true }
""")
	var expected = {
		"type": 'document',
		"content": [{
			"type": 'content',
			"content": [
				{
					"type": 'options',
					"name": null,
					"speaker": null,
					"id": null,
					"tags": null,
					"id_suffixes": null,
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
									"mode":  'once', "id": null, "speaker": null, "tags": null,
									"id_suffixes": null,
									"content": { "type": 'content', "content": [{ "type": 'line', "value": 'yes', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }]},
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
									"mode":  'once', "id": null, "speaker": null, "tags": null,
									"id_suffixes": null,
									"content": { "type": 'content', "content": [ { "type": 'line', "value": 'no', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }, ]},
								},
							},
						},

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
									"mode":  'once', "id": null, "speaker": null, "tags": null,
									"id_suffixes": null,
									"content": { "type": 'content', "content": [{ "type": 'line', "value": 'yes', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }]},
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
									"mode":  'once', "id": null, "speaker": null, "tags": null,
									"id_suffixes": null,
									"content": { "type": 'content', "content": [ { "type": 'line', "value": 'no', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }, ]},
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
										"variable": { "type": 'variable', "name": 'yes', },
										"operation": 'assign',
										"value": { "type": 'literal', "name": 'boolean', "value": true, },
									},
								],
							},
							"content": {
								"type": "conditional_content",
								"conditions": { "type": "variable", "name": "yes" },
								"content": {
									"type": "action_content",
									"action": {
										"type": 'assignments',
										"assignments": [
											{
												"type": 'assignment',
												"variable": { "type": 'variable', "name": 'one_more', },
												"operation": 'assign',
												"value": { "type": 'literal', "name": 'boolean', "value": true, },
											},
										],
									},
									"content": {
										"type": 'option',
										"name": 'yes',
										"mode":  'once', "id": null, "speaker": null, "tags": null,
										"id_suffixes": null,
										"content": { "type": 'content', "content": [ { "type": 'line', "value": 'yes', "id": null, "speaker": null, "tags": null, "id_suffixes": null, }, ]},
									},
								},
							},
						},
					],
				},
			],
		}],
		"blocks": [],
	}
	assert_eq_deep(result, expected)
