extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input, include_meta = false):
	var parser = Parser.new()
	return parser.parse(input, include_meta)


func _line(line):
	return {
		"type": "line",
		"text": line.get("text"),
		"speaker": line.get("speaker"),
		"id": line.get("id"),
		"tags": line.get("tags", [])
	}


func _options(options):
	return {
		"type": "options",
		"name": options.get("name"),
		"id": options.get("id"),
		"tags": options.get("tags", []),
		"speaker": options.get("speaker"),
		"options": options.get("options")
	}


func _option(option):
	return {
		"label": option.get("label"),
		"speaker": option.get("speaker"),
		"id": option.get("id"),
		"tags": option.get("tags", [])
	}


func _option_with_visibility_prop(option):
	var o = _option(option)
	o.is_visible = option.get("is_visible")
	return o


func _get_next_options_content(dialogue):
	var content = dialogue.get_content()
	while content.type != "options":
		content = dialogue.get_content()
	return content


func test_simple_lines_file():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" }),
		_line({ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" }),
		_line({ "type": "line", "text": "What?", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" }),
		_line({ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(dialogue.get_content(), line)


func test_translate_files():
	TranslationServer.set_locale("pt_BR")
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" }),
		_line({ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" }),
		_line({ "type": "line", "text": "What?", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "Tradução", "speaker": "Mia", "id": "145" }),
		_line({ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(dialogue.get_content(), line)

	TranslationServer.set_locale("en")


func _initialize_dictionary():
	var t = Translation.new()
	t.locale = "en"
	t.add_message("abc", "simple key")
	t.add_message("abc&P", "simple key with suffix 1")
	t.add_message("abc&P&S", "simple key with suffix 1 and 2")
	t.add_message("abc&S", "simple key with only suffix 2")
	t.add_message("abc__P", "this uses custom suffix")
	TranslationServer.add_translation(t)
	TranslationServer.set_locale("en")


func _initialize_interpreter_for_suffix_test():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("This should be replaced $abc&suffix_1&suffix_2")
	interpreter.init(content)
	return interpreter


func test_id_suffix_returns_line_with_suffix_value():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()
	interpreter.set_variable("suffix_1", "P");

	assert_eq(interpreter.get_content().text, "simple key with suffix 1")


func test_id_suffix_returns_line_with_multiple_suffixes_value():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()
	interpreter.set_variable("suffix_1", "P");
	interpreter.set_variable("suffix_2", "S");

	assert_eq(interpreter.get_content().text, "simple key with suffix 1 and 2")


func test_id_suffix_ignores_suffix_if_variable_is_not_set():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()
	interpreter.set_variable("suffix_1", "S");

	assert_eq(interpreter.get_content().text, "simple key with only suffix 2")


func test_id_suffix_ignores_all_suffixes_when_variables_not_set():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()

	assert_eq(interpreter.get_content().text, "simple key")


func test_id_suffix_fallsback_to_id_without_prefix_when_not_found():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()

	interpreter.set_variable("suffix_1", "banana");

	assert_eq(interpreter.get_content().text, "simple key")


func test_id_suffix_works_with_options():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
first topics $abc&suffix1
	* option 1 $abc&suffix2
		blah
*
	blah $abc&suffix1&suffix2""")
	interpreter.init(content)

	_initialize_dictionary()

	interpreter.set_variable("suffix1", "P");
	interpreter.set_variable("suffix2", "S");
	var first_options = interpreter.get_content();
	assert_eq(first_options.name, "simple key with suffix 1")
	assert_eq(first_options.options[0].label, "simple key with only suffix 2")

	interpreter.choose(0);
	interpreter.get_content()

	var second_options = interpreter.get_content();
	assert_eq(second_options.options[0].label, "simple key with suffix 1 and 2")


func test_interpreter_option_id_lookup_suffix():
	_initialize_dictionary()

	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("This should be replaced $abc&suffix_1&suffix_2")
	interpreter.init(content, { "id_suffix_lookup_separator": "__" })
	interpreter.set_variable("suffix_1", "P");

	assert_eq(interpreter.get_content().text, "this uses custom suffix")


func test_options():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('options')


	var first_part = [
		_line({ "type": "line", "text": "what do you want to talk about?", "speaker": "npc" }),
		_options({ "options": [_option({ "label": "Life" }), _option({ "label": "The universe" }), _option({ "label": "Everything else...", "tags": ["some_tag"] })] }),
		]

	var life_option = [
		_line({ "type": "line", "text": "I want to talk about life!", "speaker": "player" }),
		_line({ "type": "line", "text": "Well! That's too complicated...", "speaker": "npc" }),
	]

	for line in first_part:
		assert_eq_deep(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in life_option:
		assert_eq_deep(dialogue.get_content(), line)


func test_fallback_options():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("*= a\n>= b\nend")
	interpreter.init(content)

	assert_eq_deep(interpreter.get_content(), _options({ "options": [_option({ "label": "a" }), _option({ "label": "b" }) ] }))
	interpreter.choose(0)
	assert_eq_deep(interpreter.get_content().text, "a")
	assert_eq_deep(interpreter.get_content().text, "end")
	interpreter.select_block()
	assert_eq_deep(interpreter.get_content(), _line({ "type": "line", "text": "b" }))


func test_include_hidden_options():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
* a { this_condition_is_false }
  line a
* b
  line b
""")
	interpreter.init(content, { "include_hidden_options": true })

	var options = interpreter.get_content()

	assert_eq(options.options.size(), 2)
	assert_eq_deep(
		options.options,
		[
			_option_with_visibility_prop({ "label": "a", "is_visible": false }),
			_option_with_visibility_prop({ "label": "b", "is_visible": true })
		]
	)

	# does not change options when choosing an invisible option
	interpreter.choose(0)
	assert_eq(interpreter.get_content().type, "options")

	interpreter.choose(1)
	assert_eq(interpreter.get_content().text, "line b")


func test_blocks_and_diverts():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('diverts', 'initial_dialog')


	var initial_dialogue = [
		_line({ "type": "line", "text": "what do you want to talk about?", "speaker": "npc" }),
		_options({ "options": [_option({ "label": "Life" }),_option({ "label": "The universe" }), _option({ "label": "Everything else..." }), _option({ "label": "Goodbye!" })] }),
	]

	var life_option = [
		_line({ "type": "line", "text": "I want to talk about life!", "speaker": "player" }),
		_line({ "type": "line", "text": "Well! That's too complicated...", "speaker": "npc" }),
		# back to initial dialogue
		_options({ "options": [_option({ "label": "The universe" }), _option({ "label": "Everything else..." }), _option({ "label": "Goodbye!" })] })
	]

	var everything_option = [
		_line({ "type": "line", "text": "What about everything else?", "speaker": "player" }),
		_line({ "type": "line", "text": "I don't have time for this...", "speaker": "npc" }),
		# back to initial dialogue
		_options({ "options": [_option({ "label": "The universe" }), _option({ "label": "Goodbye!" })] })
	]

	var universe_option = [
		_line({ "type": "line", "text": "I want to talk about the universe!", "speaker": "player" }),
		_line({ "type": "line", "text": "That's too complex!", "speaker": "npc" }),
		# back to initial dialogue
		_options({ "options": [_option({ "label": "Goodbye!" })] })
	]

	var goodbye_option = [
		_line({ "type": "line", "text": "See you next time!", "speaker": "player" }),
		{ "type": "end" },
	]

	for line in initial_dialogue:
		assert_eq_deep(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in life_option:
		assert_eq_deep(dialogue.get_content(), line)

	dialogue.choose(1)

	for line in everything_option:
		assert_eq_deep(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in universe_option:
		assert_eq_deep(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in goodbye_option:
		assert_eq_deep(dialogue.get_content(), line)


func test_variations():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variations')

	var sequence = ["Hello", "Hi", "Hey"]
	var random_sequence = ["Hello", "Hi", "Hey"]
	var once = ["nested example", "here I am"]
	var random_cycle = ["multiline example do you think it works?", "yep"]

	for _i in range(4):
		dialogue.start()

		# sequence
		assert_eq_deep(
			dialogue.get_content().text,
			sequence[0]
		)

		if sequence.size() > 1:
			sequence.pop_front()

		# random sequence
		var rs = dialogue.get_content().text
		assert_has(random_sequence, rs)
		if random_sequence.size() > 1:
			random_sequence.erase(rs)

		# once each
		if (once.size() != 0):
			var o = dialogue.get_content().text
			assert_has(once, o)
			once.erase(o)

		# random cycle
		var rc = dialogue.get_content().text
		assert_has(random_cycle, rc)
		random_cycle.erase(rc)
		if random_cycle.size() == 0:
			random_cycle = ["multiline example do you think it works?", "yep"]


func test_variation_default_shuffle():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("( shuffle \n - A\n - B\n)\nend\n")
	interpreter.init(content)

	var random_default_cycle = ["A", "B"]
	for _i in range(5):
		interpreter.select_block()
		var rdc = interpreter.get_content().text
		assert_has(random_default_cycle, rdc)


func test_all_variations_not_available():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("(\n - { a } A\n -  { b } B\n)\nend\n")
	interpreter.init(content)

	assert_eq_deep(interpreter.get_content().text, 'end')


func test_logic():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('logic')
	assert_eq_deep(dialogue.get_content().text, "variable was initialized with 1")
	assert_eq_deep(dialogue.get_content().text, "setting multiple variables")
	assert_eq_deep(dialogue.get_content().text, "4 == 4.  3 == 3")
	assert_eq_deep(dialogue.get_content().text, "variable was initialized with 3")
	assert_eq_deep(dialogue.get_content().text, "variable remains as 3 when init assign")
	assert_eq_deep(dialogue.get_content().text, "This is a block")
	assert_eq_deep(dialogue.get_content().text, "inside a condition")
	assert_eq_deep(dialogue.get_content().type, "end")


func test_assigments():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
{ set a = 1, a += 1} this should be %a%
{ set b = 1, b -= 2} this should be %b%
{ set c = 1, c *= 3} this should be %c%
{ set d = 1, d /= 4} this should be %d%
{ set e = 1, e %= 5} this should be %e%
{ set f = 2, f ^= 2} this should be %f%
{ set a = "abc", a += "def"} this should be %a%
""")
	interpreter.init(content)
	assert_eq_deep(interpreter.get_content().text, 'this should be 2')
	assert_eq_deep(interpreter.get_content().text, 'this should be -1')
	assert_eq_deep(interpreter.get_content().text, 'this should be 3')
	assert_eq_deep(interpreter.get_content().text, 'this should be 0.25')
	assert_eq_deep(interpreter.get_content().text, 'this should be 1')
	assert_eq_deep(interpreter.get_content().text, 'this should be 4')
	assert_eq_deep(interpreter.get_content().text, 'this should be abcdef')
	assert_eq_deep(interpreter.get_content().type, "end")


func test_uninitialized_increment_assigment():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
{ set a += 1} this should be %a%
{ set b -= 2} this should be %b%
{ set c *= 3} this should be %c%
{ set d /= 4} this should be %d%
{ set e %= 5} this should be %e%
{ set f ^= 5} this should be %f%
{ set g += "b"} this should be %g%
""")
	interpreter.init(content)
	assert_eq_deep(interpreter.get_content().text, 'this should be 1')
	assert_eq_deep(interpreter.get_content().text, 'this should be -2')
	assert_eq_deep(interpreter.get_content().text, 'this should be 0')
	assert_eq_deep(interpreter.get_content().text, 'this should be 0')
	assert_eq_deep(interpreter.get_content().text, 'this should be 0')
	assert_eq_deep(interpreter.get_content().text, 'this should be 0')
	assert_eq_deep(interpreter.get_content().text, 'this should be b')
	assert_eq_deep(interpreter.get_content().type, "end")


func test_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	assert_eq_deep(dialogue.get_content().text, "not")
	assert_eq_deep(dialogue.get_content().text, "equality")
	assert_eq_deep(dialogue.get_content().text, "alias equality")
	assert_eq_deep(dialogue.get_content().text, "trigger")
	assert_eq_deep(dialogue.get_content().text, "hey you")
	assert_eq_deep(dialogue.get_content().text, "hey {you}")
	assert_eq_deep(
		dialogue.get_content(),
		_options({ "options": [_option({ "label": "Life" }), _option({ "label": "The universe" })] })
	)
	dialogue.choose(1)

	assert_eq_deep(dialogue.get_content(), _line({ "type": "line", "text": "I want to talk about the universe!", "speaker": "player" }))
	assert_eq_deep(dialogue.get_content(), _line({ "type": "line", "text": "That's too complex!", "speaker": "npc" }))
	assert_eq_deep(dialogue.get_content(), _line({ "type": "line", "text": "I'm in trouble" }))
	assert_eq_deep(dialogue.get_content().type, "end")
	assert_eq_deep(dialogue.get_variable('xx'), true)


func test_set_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	dialogue.set_variable('first_time', true)
	assert_eq_deep(dialogue.get_content().text, "what do you want to talk about?")
	dialogue.set_variable('first_time', false)
	dialogue.start()
	assert_eq_deep(dialogue.get_content().text, "not")


func test_external_variables_assignments():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
{ set var = 2 }
{ set @var = 1 }
""")
	interpreter.init(content)
	assert_eq_deep(interpreter.get_content().type, 'end')
	assert_eq(interpreter.get_variable("var"), 2)
	assert_eq(interpreter.get_external_variable("var"), 1)
	interpreter.set_variable("var", 42)
	interpreter.set_external_variable("var", 43)
	assert_eq(interpreter.get_variable("var"), 42)
	assert_eq(interpreter.get_external_variable("var"), 43)


func test_external_variables_not_included_in_data():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
{ set var = 2 }
{ set @var2 = 1 }
""")
	interpreter.init(content)
	interpreter.get_content()
	interpreter.set_external_variable("var3", 42)

	assert_does_not_have(interpreter.get_data().variables, "var3")
	assert_does_not_have(interpreter.get_data().variables, "var2")
	assert_has(interpreter.get_data().variables, "var")


func test_external_variables_interpolation():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
{ set var = 2 } this is setting a regular v %var% e %@var%
{ set @var = 1} this is setting an external var v %var% e %@var%
vars where changed externally v %var% e %@var%
""")
	interpreter.init(content)
	assert_eq_deep(interpreter.get_content().text, 'this is setting a regular v 2 e ')
	assert_eq_deep(interpreter.get_content().text, 'this is setting an external var v 2 e 1')
	interpreter.set_variable("var", 42)
	interpreter.set_external_variable("var", 43)
	assert_eq_deep(interpreter.get_content().text, 'vars where changed externally v 42 e 43')


func test_data_control():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variations')

	assert_eq_deep(dialogue.get_content().text, "Hello")
	dialogue.start()
	assert_eq_deep(dialogue.get_content().text, "Hi")

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('variations')
	dialogue2.load_data(dialogue.get_data())
	assert_eq_deep(dialogue2.get_content().text, "Hey")

	dialogue.clear_data()
	dialogue.start()
	assert_eq_deep(dialogue.get_content().text, "Hello")


func test_persisted_data_control_options():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('options')

	var content = _get_next_options_content(dialogue)
	assert_eq(content.options.size(), 3)

	dialogue.choose(0)
	dialogue.start()

	content = _get_next_options_content(dialogue)
	assert_eq(content.options.size(), 2)

	var stringified_data = JSON.stringify(dialogue.get_data())

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('options')
	var test_json_conv = JSON.new()
	test_json_conv.parse(stringified_data)
	dialogue2.load_data(test_json_conv.get_data())

	var content2 = _get_next_options_content(dialogue)
	assert_eq(content2.options.size(), 2)
	assert_eq_deep(content2, content)


func test_persisted_data_control_variations():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variations')

	assert_eq_deep(dialogue.get_content().text, "Hello")
	dialogue.start()
	assert_eq_deep(dialogue.get_content().text, "Hi")

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('variations')

	var stringified_data = JSON.stringify(dialogue.get_data())

	var test_json_conv = JSON.new()
	test_json_conv.parse(stringified_data)
	dialogue2.load_data(test_json_conv.get_data())
	assert_eq_deep(dialogue2.get_content().text, "Hey")


func test_changing_block_order_does_not_affect_persistence():
	var interpreter = ClydeDialogue.Interpreter.new()
	var dialogue_block_1 = """
== block_1
* option 1
	line
* option 2
	line
"""
	var dialogue_block_2 = """
== block_2
* option 1
	line
* option 2
	line
"""

	var content = parse(dialogue_block_1 + dialogue_block_2)
	interpreter.init(content)
	interpreter.select_block("block_1")

	interpreter.get_content()
	interpreter.choose(0)

	var data = interpreter.get_data()

	var inverted_content = parse(dialogue_block_2 + dialogue_block_1)
	interpreter.init(inverted_content)
	interpreter.load_data(data)

	interpreter.select_block("block_1")

	var block_1_options = interpreter.get_content()

	interpreter.select_block("block_2")
	var block_2_options = interpreter.get_content()


	assert_eq_deep(block_1_options, _options({ "options": [_option({ "label": "option 2" })] }))
	assert_eq_deep(block_2_options, _options({ "options": [_option({ "label": "option 1" }), _option({ "label": "option 2" })] }))


var pending_events = []

func test_events():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	dialogue.connect("event_triggered",Callable(self,"_on_event_triggered"))
	dialogue.connect("variable_changed",Callable(self,"_on_variable_changed"))
	dialogue.connect("external_variable_changed",Callable(self,"_on_external_variable_changed"))

	pending_events.push_back({ "type": "variable", "name": "xx", "value": true })
	pending_events.push_back({ "type": "variable", "name": "first_time", "value": 2.0 })
	pending_events.push_back({ "type": "variable", "name": "a", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "b", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "c", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "d", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "a", "value": 6.0 })
	pending_events.push_back({ "type": "variable", "name": "a", "value": -10.0 })
	pending_events.push_back({ "type": "event", "name": "some_event" })
	pending_events.push_back({ "type": "event", "name": "another_event" })
	pending_events.push_back({ "type": "variable", "name": "a", "value": -14.0 })
	pending_events.push_back({ "type": "variable", "name": "b", "value": 1.0 })
	pending_events.push_back({ "type": "variable", "name": "c", "value": "hello" })
	pending_events.push_back({ "type": "variable", "name": "a", "value": 4.0 })
	pending_events.push_back({ "type": "variable", "name": "hp", "value": 5.0 })
	pending_events.push_back({ "type": "variable", "name": "s", "value": false })
	pending_events.push_back({ "type": "variable", "name": "x", "value": true })
	pending_events.push_back({ "type": "variable", "name": "ex", "value": true })

	while true:
		var res = dialogue.get_content()
		if res.type == "end":
			break;
		if res.type == "options":
			dialogue.choose(0)

	assert_eq(pending_events.size(), 0)



func _on_variable_changed(var_name, value, _previous_value):
	for e in pending_events:
		if e.type == 'variable' and e.name == var_name and  typeof(e.value) == typeof(value) and  e.value == value:
			pending_events.erase(e)


func _on_external_variable_changed(var_name, value, _previous_value):
	for e in pending_events:
		if e.type == 'variable' and e.name == var_name and  typeof(e.value) == typeof(value) and  e.value == value:
			pending_events.erase(e)


func _on_event_triggered(event_name):
	for e in pending_events:
		if e.type == 'event' and e.name == event_name:
			pending_events.erase(e)


func test_file_path_without_extension():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" }),
		_line({ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" }),
		_line({ "type": "line", "text": "What?", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" }),
		_line({ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(dialogue.get_content(), line)

func test_uses_configured_dialogue_folder():
	var dialogue = ClydeDialogue.new()
	dialogue.dialogue_folder = 'res://addons/clyde/examples/dialogues'
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" }),
		_line({ "type": "line", "text": "Don't you hate that?", "speaker": "Mia" }),
		_line({ "type": "line", "text": "What?", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "Uncomfortable silences. Why do we feel it's necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" }),
		_line({ "type": "line", "text": "I don't know. That's a good question.", "speaker": "Vincent" }),
		_line({ "type": "line", "text": "That's when you know you've found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(dialogue.get_content(), line)


func test_has_blocks():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('blocks')
	assert_true(dialogue.has_block("intro"), "Should have block")
	assert_false(dialogue.has_block("some-block-that-definitely-doesnt-exist"), "Should not have block")


func test_returning_meta_when_available():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("""
first line
* first option
second option
	* option
""", true)
	interpreter.init(content)

	var first_line = _line({ "type": "line", "text": "first line" })
	first_line.meta = { "line": 1, "column": 0 }
	var first_option = _options({ "options": [_option({"label": "first option"})] })
	first_option.meta = { "line": 2, "column": 0 }
	var second_option = _options({ "name": "second option", "options": [_option({"label": "option"})] })
	second_option.meta = { "line": 3, "column": 0 }

	assert_eq_deep(interpreter.get_content(), first_line)
	assert_eq_deep(interpreter.get_content(), first_option)
	interpreter.choose(0)
	assert_eq_deep(interpreter.get_content(), second_option)
