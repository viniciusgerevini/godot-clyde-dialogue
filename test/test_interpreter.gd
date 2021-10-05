extends "res://addons/gut/test.gd"

var Parser = preload("res://addons/clyde/parser/Parser.gd")

func parse(input):
	var parser = Parser.new()
	return parser.parse(input)


func _line(line):
	return {
		"type": "line",
		"text": line.get("text"),
		"speaker": line.get("speaker"),
		"id": line.get("id"),
		"tags": line.get("tags")
	 }


func _options(options):
	return {
		"type": "options",
		"name": options.get("name"),
		"id": options.get("id"),
		"tags": options.get("tags"),
		"speaker": options.get("speaker"),
		"options": options.get("options")
	 }


func _option(option):
	return {
		"label": option.get("label"),
		"speaker": option.get("speaker"),
		"id": option.get("id"),
		"tags": option.get("tags")
	}


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
	var content = parse("* a\n> b\nend")
	interpreter.init(content)

	assert_eq_deep(interpreter.get_content(), _options({ "options": [_option({ "label": "a" }), _option({ "label": "b" }) ] }))
	interpreter.choose(0)
	assert_eq_deep(interpreter.get_content().text, "a")
	assert_eq_deep(interpreter.get_content().text, "end")
	interpreter.select_block()
	assert_eq_deep(interpreter.get_content(), _line({ "type": "line", "text": "b" }))

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
		null
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


func _test_variation_default_shuffle_is_cycle():
	var interpreter = ClydeDialogue.Interpreter.new()
	var content = parse("( shuffle \n- { a } A\n -  { b } B\n)\nend\n")
	interpreter.init(content)

	var random_default_cycle = ["a", "b"]
	for _i in range(2):
		var rdc = interpreter.get_content().text
		assert_has(random_default_cycle, rdc)
		random_default_cycle.erase(rdc)

	assert_eq(random_default_cycle.size(), 0)
	# should re-shuffle after exausting all options
	random_default_cycle = ["a", "b"]
	for _i in range(2):
		var rdc = interpreter.get_content().text
		assert_has(random_default_cycle, rdc)
		random_default_cycle.erase(rdc)

	assert_eq(random_default_cycle.size(), 0)


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
	assert_eq_deep(dialogue.get_content().text, "This is a block")
	assert_eq_deep(dialogue.get_content().text, "inside a condition")
	assert_eq_deep(dialogue.get_content(), null)

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
	assert_eq_deep(dialogue.get_content(), null)
	assert_eq_deep(dialogue.get_variable('xx'), true)

func test_set_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	dialogue.set_variable('first_time', true)
	assert_eq_deep(dialogue.get_content().text, "what do you want to talk about?")
	dialogue.set_variable('first_time', false)
	dialogue.start()
	assert_eq_deep(dialogue.get_content().text, "not")


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


var pending_events = []

func test_events():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	dialogue.connect("event_triggered", self, "_on_event_triggered")
	dialogue.connect("variable_changed", self, "_on_variable_changed")

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

	while true:
		var res = dialogue.get_content()
		if not res:
			break;
		if res.type == 'options':
			dialogue.choose(0)

	assert_eq(pending_events.size(), 0)



func _on_variable_changed(name, value, _previous_value):
	for e in pending_events:
		if e.type == 'variable' and e.name == name and  typeof(e.value) == typeof(value) and  e.value == value:
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
	dialogue.dialogue_folder = 'res://dialogues'
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
