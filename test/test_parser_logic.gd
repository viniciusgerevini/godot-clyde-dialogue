extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)

func _create_doc_payload(content = [], blocks = []):
	return {
		"type": 'document',
		"content": [{
			"type": "content",
			"content": content
		}],
		"blocks": blocks
	}

func test_condition_single_var():
	var result = parse("{ some_var } This is conditional")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": { "type": "line", "value": "This is conditional", "speaker": null, "id": null, "tags": null, }
		},
	])
	assert_eq_deep(result, expected)

func test_condition_with_multiline_dialogue():
	var result = parse("""{ another_var } This is conditional
		multiline
""")

	var expected = _create_doc_payload([{
		"type": "conditional_content",
		"conditions": { "type": "variable", "name": "another_var" },
		"content": { "type": "line", "value": "This is conditional multiline", "speaker": null, "id": null, "tags": null, }
	}])
	assert_eq_deep(result, expected)


func test_not_operator():
	var result = parse("{ not some_var } This is conditional")

	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": {
				"type": "expression",
				"name": "not",
				"elements": [{ "type": "variable", "name": "some_var" }]
			},
			"content": { "type": "line", "value": "This is conditional", "speaker": null, "id": null, "tags": null, }
		}
	])
	assert_eq_deep(result, expected)


func test_and_operator():
	var result = parse("""{ first_time && second_time } npc: what do you want to talk about? """)

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'and',
				"elements": [
					{ "type": 'variable', "name": 'first_time', },
					{ "type": 'variable', "name": 'second_time', },
				],
			},
			"content": { "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)


func test_multiple_logical_checks_and_and_or():
	var result = parse("{ first_time and second_time or third_time } npc: what do you want to talk about?")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'or',
				"elements": [
					{
						"type": 'expression',
						"name": 'and',
						"elements": [
							{ "type": 'variable', "name": 'first_time', },
							{ "type": 'variable', "name": 'second_time', },
						],
					},
					{ "type": 'variable', "name": 'third_time', },
				],
			},
			"content": { "type": 'line', "value": 'what do you want to talk about?', "speaker": 'npc', "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)


func test_multiple_equality_check():
	var result = parse("{ first_time == second_time or third_time != fourth_time } equality")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'or',
				"elements": [
					{
						"type": 'expression',
						"name": 'equal',
						"elements": [
							{ "type": 'variable', "name": 'first_time', },
							{ "type": 'variable', "name": 'second_time', },
						],
					},
					{
						"type": 'expression',
						"name": 'not_equal',
						"elements": [
							{ "type": 'variable', "name": 'third_time', },
							{ "type": 'variable', "name": 'fourth_time', },
						],
					},
				],
			},
			"content": { "type": 'line', "value": 'equality', "speaker": null, "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)


func test_multiple_alias_equality_check():
	var result = parse("{ first_time is second_time or third_time isnt fourth_time } alias equality")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'or',
				"elements": [
					{
						"type": 'expression',
						"name": 'equal',
						"elements": [
							{ "type": 'variable', "name": 'first_time', },
							{ "type": 'variable', "name": 'second_time', },
						],
					},
					{
						"type": 'expression',
						"name": 'not_equal',
						"elements": [
							{ "type": 'variable', "name": 'third_time', },
							{ "type": 'variable', "name": 'fourth_time', },
						],
					},
				],
			},
			"content": { "type": 'line', "value": 'alias equality', "speaker": null, "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)


func test_less_or_greater():
	var result = parse("{ first_time < second_time or third_time > fourth_time } comparison")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'or',
				"elements": [
					{
						"type": 'expression',
						"name": 'less_than',
						"elements": [
							{ "type": 'variable', "name": 'first_time', },
							{ "type": 'variable', "name": 'second_time', },
						],
					},
					{
						"type": 'expression',
						"name": 'greater_than',
						"elements": [
							{ "type": 'variable', "name": 'third_time', },
							{ "type": 'variable', "name": 'fourth_time', },
						],
					},
				],
			},
			"content": { "type": 'line', "value": 'comparison', "speaker": null, "id": null, "tags": null, },
		},
	])
	assert_eq_deep(result, expected)


func test_less_or_equal_and_greater_or_equal():
	var result = parse("{ first_time <= second_time and third_time >= fourth_time } second comparison")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'and',
				"elements": [
					{
						"type": 'expression',
						"name": 'less_or_equal',
						"elements": [
							{ "type": 'variable', "name": 'first_time', },
							{ "type": 'variable', "name": 'second_time', },
						],
					},
					{
						"type": 'expression',
						"name": 'greater_or_equal',
						"elements": [
							{ "type": 'variable', "name": 'third_time', },
							{ "type": 'variable', "name": 'fourth_time', },
						],
					},
				],
			},
			"content": { "type": 'line', "value": 'second comparison', "speaker": null, "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)



func test__complex_precendence_case():
	var result = parse("{ first_time > x + y - z * d / e % b } test")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'greater_than',
				"elements": [
					{ "type": 'variable', "name": 'first_time', },
					{
						"type": 'expression',
						"name": 'sub',
						"elements": [
							{
								"type": 'expression',
								"name": 'add',
								"elements": [
									{ "type": 'variable', "name": 'x', },
									{ "type": 'variable', "name": 'y', },
								],
							},
							{
								"type": 'expression',
								"name": 'mod',
								"elements": [
									{
										"type": 'expression',
										"name": 'div',
										"elements": [
											{
												"type": 'expression',
												"name": 'mult',
												"elements": [
													{ "type": 'variable', "name": 'z', },
													{ "type": 'variable', "name": 'd', },
												],
											},
											{ "type": 'variable', "name": 'e', },
										],
									},
									{ "type": 'variable', "name": 'b', },
								],
							},
						],
					},
				],
			},
			"content": { "type": 'line', "value": 'test', "speaker": null, "id": null, "tags": null, },
		},
	])
	assert_eq_deep(result, expected)



func test_number_literal():
	var result = parse("{ first_time > 0 } hey")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'greater_than',
				"elements": [
					{ "type": 'variable', "name": 'first_time', },
					{ "type": 'literal', "name": 'number', "value": 0.0, },
				],
			},
			"content": { "type": 'line', "value": 'hey', "speaker": null, "id": null, "tags": null, },
		},
	])
	assert_eq_deep(result, expected)



func test__null_token():
	var result = parse("{ first_time != null } ho")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'not_equal',
				"elements": [
					{ "type": 'variable', "name": 'first_time', },
					{ "type": 'null', },
				],
			},
			"content": { "type": 'line', "value": 'ho', "speaker": null, "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)



func test_boolean_literal():
	var result = parse("{ first_time is false } let's go")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'equal',
				"elements": [
					{ "type": 'variable', "name": 'first_time', },
					{ "type": 'literal', "name": 'boolean', "value": false, },
				],
			},
			"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)


func test_string_literal():
	var result = parse("{ first_time is \"hello darkness >= my old friend\" } let's go")

	var expected = _create_doc_payload([
		{
			"type": 'conditional_content',
			"conditions": {
				"type": 'expression',
				"name": 'equal',
				"elements": [
					{ "type": 'variable', "name": 'first_time', },
					{ "type": 'literal', "name": 'string', "value": 'hello darkness >= my old friend', },
				],
			},
			"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
		}
	])
	assert_eq_deep(result, expected)

func test_condition_before_line_with_keyword():
	var result = parse("{ when some_var } This is conditional")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": { "type": "line", "value": "This is conditional", "speaker": null, "id": null, "tags": null, }
		},
	])
	assert_eq_deep(result, expected)


func test_condition_after_line():
	var result = parse("This is conditional { when some_var }")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": { "type": "line", "value": "This is conditional", "speaker": null, "id": null, "tags": null, }
		},
	])
	assert_eq_deep(result, expected)


func test_condition_after_line_without_when():
	var result = parse("This is conditional { some_var }")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": { "type": "line", "value": "This is conditional", "speaker": null, "id": null, "tags": null, }
		},
	])
	assert_eq_deep(result, expected)



func test_conditional_divert():
	var result = parse("{ some_var } -> some_block")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": { "type": "divert", "target": "some_block", }
		},
	])
	assert_eq_deep(result, expected)


func test_conditional_divert_after():
	var result = parse("-> some_block { some_var }")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": { "type": "divert", "target": "some_block", }
		},
	])
	assert_eq_deep(result, expected)


func test_conditional_option():
	var result = parse("""
* { some_var } option 1
* option 2 { when some_var }
* { some_other_var } option 3
""")
	var expected = _create_doc_payload([{
		"type": 'options',
		"name": null,
    "speaker": null, "id": null, "tags": null,
		"content": [
			{
				"type": "conditional_content",
				"conditions": { "type": "variable", "name": "some_var" },
				"content": {
					"type": 'option',
					"name": 'option 1',
					"mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 1', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
			{
				"type": "conditional_content",
				"conditions": { "type": "variable", "name": "some_var" },
				"content": {
					"type": 'option',
					"name": 'option 2',
					"mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 2', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
			{
				"type": "conditional_content",
				"conditions": { "type": "variable", "name": "some_other_var" },
				"content": {
					"type": 'option',
					"name": 'option 3',
					"mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 3', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
		],
			}
	])
	assert_eq_deep(result, expected)


func test_conditional_indented_block():
	var result = parse("""
{ some_var }
	This is conditional
	This is second conditional
	This is third conditional
""")
	var expected = _create_doc_payload([
		{
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": {
				"type": 'content',
				"content": [
					{ "type": "line", "value": "This is conditional", "speaker": null, "id": null, "tags": null, },
					{ "type": "line", "value": "This is second conditional", "speaker": null, "id": null, "tags": null, },
					{ "type": "line", "value": "This is third conditional", "speaker": null, "id": null, "tags": null, }
				]
			}
		},
	])
	assert_eq_deep(result, expected)


const assignments = [
	[ '=', 'assign'],
	[ '+=', 'assign_sum'],
	[ '-=', 'assign_sub'],
	[ '*=', 'assign_mult'],
	[ '/=', 'assign_div'],
	[ '%=', 'assign_mod'],
	[ '^=', 'assign_pow'],
]

func test_assignments():
	for a in assignments:
		_assignment_tests(a[0], a[1])


func _assignment_tests(token, node_name):
	var result = parse("{ set a %s 2 } let's go" % token)
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'a', },
					"operation": node_name,
					"value": { "type": 'literal', "name": 'number', "value": 2.0, },
				},
			],
		},
		"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
	}])
	assert_eq_deep(result, expected)


func test_assignment_with_expression():
	var result = parse('{ set a -= 4 ^ 2 } let\'s go')
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": {
						"type": 'variable',
						"name": 'a',
					},
					"operation": 'assign_sub',
					"value": {
						"type": 'expression',
						"name": 'pow',
						"elements": [
							{
								"type": 'literal',
								"name": 'number',
								"value": 4.0,
							},
							{
								"type": 'literal',
								"name": 'number',
								"value": 2.0,
							},
						],
					},
				},
			],
		},
		"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
	}])
	assert_eq_deep(result, expected)


func test_assignment_with_expression_after():
	var result = parse('multiply { set a = a * 2 }')
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": {
						"type": 'variable',
						"name": 'a',
					},
					"operation": 'assign',
					"value": {
						"type": 'expression',
						"name": 'mult',
						"elements": [
							{
								"type": 'variable',
								"name": 'a',
							},
							{
								"type": 'literal',
								"name": 'number',
								"value": 2.0,
							},
						],
					},
				},
			],
		},
		"content": { "type": 'line', "value": 'multiply', "speaker": null, "id": null, "tags": null, },
	}])
	assert_eq_deep(result, expected)


func test_chaining_assigments():
	var result = parse('{ set a = b = c = d = 3 } let\'s go')
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": {
						"type": 'variable',
						"name": 'a',
					},
					"operation": 'assign',
					"value": {
						"type": 'assignment',
						"variable": {
							"type": 'variable',
							"name": 'b',
						},
						"operation": 'assign',
						"value": {
							"type": 'assignment',
							"variable": {
								"type": 'variable',
								"name": 'c',
							},
							"operation": 'assign',
							"value": {
								"type": 'assignment',
								"variable": {
									"type": 'variable',
									"name": 'd',
								},
								"operation": 'assign',
								"value": {
									"type": 'literal',
									"name": 'number',
									"value": 3.0,
								},
							},
						},
					},
				},
			],
		},
		"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
	}])
	assert_eq_deep(result, expected)


func test_chaining_assigment_ending_with_variable():
		var result = parse('{ set a = b = c } let\'s go')
		var expected = _create_doc_payload([{
			"type": 'action_content',
			"action": {
				"type": 'assignments',
				"assignments": [
					{
						"type": 'assignment',
						"variable": {
							"type": 'variable',
							"name": 'a',
						},
						"operation": 'assign',
						"value": {
							"type": 'assignment',
							"variable": {
								"type": 'variable',
								"name": 'b',
							},
							"operation": 'assign',
							"value": {
								"type": 'variable',
								"name": 'c',
							},
						},
					},
				],
			},
			"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
		}])
		assert_eq_deep(result, expected)


func test_multiple_assigments_block():
	var result = parse('{ set a -= 4, b=1, c = "hello" } hey you')
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": {
						"type": 'variable',
						"name": 'a',
					},
					"operation": 'assign_sub',
					"value": {
						"type": 'literal',
						"name": 'number',
						"value": 4.0,
					},
				},
				{
					"type": 'assignment',
					"variable": {
						"type": 'variable',
						"name": 'b',
					},
					"operation": 'assign',
					"value": {
						"type": 'literal',
						"name": 'number',
						"value": 1.0,
					},
				},
				{
					"type": 'assignment',
					"variable": {
						"type": 'variable',
						"name": 'c',
					},
					"operation": 'assign',
					"value": {
						"type": 'literal',
						"name": 'string',
						"value": 'hello',
					},
				},
			],
		},
		"content": { "type": 'line', "value": 'hey you', "speaker": null, "id": null, "tags": null, },
	}])
	assert_eq_deep(result, expected)


func test_assignment_after_line():
	var result = parse("let's go { set a = 2 }")
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'a', },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 2.0, },
				},
			],
		},
		"content": { "type": 'line', "value": 'let\'s go', "speaker": null, "id": null, "tags": null, },
	}])
	assert_eq_deep(result, expected)


func test_standalone_assignment():
	var result = parse("""
{ set a = 2 }
{ set b = 3 }""")

	var expected = _create_doc_payload([
		{
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'a', },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 2.0, },
				},
			],
		},
		{
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'b', },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 3.0, },
				},
			],
		}
	])
	assert_eq_deep(result, expected)


func test_options_assignment():
	var result = parse("""
* { set a = 2 } option 1
* option 2 { set b = 3 }
* { set c = 4 } option 3
""")
	var expected = _create_doc_payload([{
		"type": 'options',
		"name": null,
    "speaker": null, "id": null, "tags": null,
		"content": [
			{
				"type": "action_content",
				"action": {
					"type": 'assignments',
					"assignments": [{ "type": 'assignment', "variable": { "type": 'variable', "name": 'a', }, "operation": 'assign', "value": { "type": 'literal', "name": 'number', "value": 2.0, }, }, ],
				},
				"content": { "type": 'option', "name": 'option 1', "mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 1', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
			{
				"type": "action_content",
				"action": {
					"type": 'assignments',
					"assignments": [{ "type": 'assignment', "variable": { "type": 'variable', "name": 'b', }, "operation": 'assign', "value": { "type": 'literal', "name": 'number', "value": 3.0, }, }, ],
				},
				"content": { "type": 'option', "name": 'option 2', "mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 2', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
			{
				"type": "action_content",
				"action": {
					"type": 'assignments',
					"assignments": [{ "type": 'assignment', "variable": { "type": 'variable', "name": 'c', }, "operation": 'assign', "value": { "type": 'literal', "name": 'number', "value": 4.0, }, }, ],
				},
				"content": { "type": 'option', "name": 'option 3', "mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 3', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
		],
		}
	])
	assert_eq_deep(result, expected)


func test_divert_with_assignment():
	var result = parse("-> go { set a = 2 }")
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [
				{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'a', },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 2.0, },
				},
			],
		},
		"content": { "type": 'divert', "target": 'go' },
	}])
	assert_eq_deep(result, expected)


func test_trigger_event():
	var result = parse("{ trigger some_event } trigger")
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'events',
			"events": [{ "type": 'event', "name": 'some_event' }],
		},
		"content": {
			"type": 'line',
			"value": 'trigger', "speaker": null, "id": null, "tags": null,
		},
	}])
	assert_eq_deep(result, expected)


func test_trigger_multiple_events_in_one_block():
	var result = parse("{ trigger some_event, another_event } trigger")
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'events',
			"events": [
				{ "type": 'event', "name": 'some_event' },
				{ "type": 'event', "name": 'another_event' }
		],
		},
		"content": {
			"type": 'line',
			"value": 'trigger', "speaker": null, "id": null, "tags": null,
		},
	}])
	assert_eq_deep(result, expected)


func test_standalone_trigger_event():
	var result = parse("{ trigger some_event }")
	var expected = _create_doc_payload([{
		"type": 'events',
		"events": [
			{ "type": 'event', "name": 'some_event' },
		],
	}])
	assert_eq_deep(result, expected)


func test_trigger_event_after_line():
	var result = parse("trigger { trigger some_event }")
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'events',
			"events": [{ "type": 'event', "name": 'some_event' }],
		},
		"content": {
			"type": 'line',
			"value": 'trigger', "speaker": null, "id": null, "tags": null,
		},
	}])
	assert_eq_deep(result, expected)


func test_options_trigger():
	var result = parse("""
* { trigger a } option 1
* option 2 { trigger b }
* { trigger c } option 3
""")
	var expected = _create_doc_payload([{
		"type": 'options',
		"name": null,
    "speaker": null, "id": null, "tags": null,
		"content": [
			{
				"type": "action_content",
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'a' }],
				},
				"content": { "type": 'option', "name": 'option 1', "mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 1', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
			{
				"type": "action_content",
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'b' }],
				},
				"content": { "type": 'option', "name": 'option 2', "mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 2', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
			{
				"type": "action_content",
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'c' }],
				},
				"content": { "type": 'option', "name": 'option 3', "mode": 'once', "speaker": null, "id": null, "tags": null,
					"content": {
						"type": 'content',
						"content": [
							{ "type": 'line', "value": 'option 3', "speaker": null, "id": null, "tags": null, },
						],
					},
				},
			},
		],
		}
	])
	assert_eq_deep(result, expected)


func test_multiple_logic_blocks_in_the_same_line():
	var result = parse("{ some_var } {set something = 1} { trigger event }")
	var expected = _create_doc_payload([{
		"type": "conditional_content",
		"conditions": { "type": "variable", "name": "some_var" },
		"content": {
			"type": 'action_content',
			"action": {
				"type": 'assignments',
				"assignments": [{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'something' },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 1.0 },
				}],
			},
			"content": {
				"type": 'events',
				"events": [{ "type": 'event', "name": 'event' } ],
			},
		},
	}])
	assert_eq_deep(result, expected)


func test_multiple_logic_blocks_in_the_same_line_before():
	var result = parse("{ some_var } {set something = 1} { trigger event } hello")
	var expected = _create_doc_payload([{
		"type": "conditional_content",
		"conditions": { "type": "variable", "name": "some_var" },
		"content": {
			"type": 'action_content',
			"action": {
				"type": 'assignments',
				"assignments": [{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'something' },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 1.0 },
				}],
			},
			"content": {
				"type": 'action_content',
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'event' } ],
				},
				"content": {
					"type": 'line',
					"value": 'hello', "speaker": null, "id": null, "tags": null,
				},
			},
		},
	}])
	assert_eq_deep(result, expected)


func test_multiple_logic_blocks_in_the_same_line_after():
	var result = parse("hello { when some_var } {set something = 1} { trigger event }")
	var expected = _create_doc_payload([{
		"type": "conditional_content",
		"conditions": { "type": "variable", "name": "some_var" },
		"content": {
			"type": 'action_content',
			"action": {
				"type": 'assignments',
				"assignments": [{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'something' },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 1.0 },
				}],
			},
			"content": {
				"type": 'action_content',
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'event' } ],
				},
				"content": {
					"type": 'line',
					"value": 'hello', "speaker": null, "id": null, "tags": null,
				},
			},
		},
	}])
	assert_eq_deep(result, expected)


func test_multiple_logic_blocks_in_the_same_line_around():
	var result = parse("{ some_var } hello {set something = 1} { trigger event }")
	var expected = _create_doc_payload([{
		"type": "conditional_content",
		"conditions": { "type": "variable", "name": "some_var" },
		"content": {
			"type": 'action_content',
			"action": {
				"type": 'assignments',
				"assignments": [{
					"type": 'assignment',
					"variable": { "type": 'variable', "name": 'something' },
					"operation": 'assign',
					"value": { "type": 'literal', "name": 'number', "value": 1.0 },
				}],
			},
			"content": {
				"type": 'action_content',
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'event' } ],
				},
				"content": {
					"type": 'line',
					"value": 'hello', "speaker": null, "id": null, "tags": null,
				},
			},
		},
	}])
	assert_eq_deep(result, expected)


func test_multiple_logic_blocks_with_condition_after():
	var result = parse("{set something = 1} { some_var } { trigger event } hello")
	var expected = _create_doc_payload([{
		"type": 'action_content',
		"action": {
			"type": 'assignments',
			"assignments": [{
				"type": 'assignment',
				"variable": { "type": 'variable', "name": 'something' },
				"operation": 'assign',
				"value": { "type": 'literal', "name": 'number', "value": 1.0 },
			}],
		},
		"content": {
			"type": "conditional_content",
			"conditions": { "type": "variable", "name": "some_var" },
			"content": {
				"type": 'action_content',
				"action": {
					"type": 'events',
					"events": [{ "type": 'event', "name": 'event' } ],
				},
				"content": {
					"type": 'line',
					"value": 'hello', "speaker": null, "id": null, "tags": null,
				},
			},
		},
	}])
	assert_eq_deep(result, expected)


func test_empty_block():
	var result = parse("{} empty")
	var expected = _create_doc_payload([{
		"type": 'conditional_content',
		"content": { "type": 'line', "value": 'empty', "speaker": null, "id": null, "tags": null, },
		"conditions": null,
	}])
	assert_eq_deep(result, expected)


