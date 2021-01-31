extends './test.gd'

func _test_simple_lines_file():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/simple_lines.json')

	var lines = [
		{ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" },
		{ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" },
		{ "type": "line", "text": "What?", "speaker": "Vincent" },
		{ "type": "line", "text": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" },
		{ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" },
		{ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"},
	]

	for line in lines:
		compare_content(dialogue.get_content(), line)


func _test_translate_files():
	TranslationServer.set_locale("pt_BR")
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/simple_lines.json')

	var lines = [
		{ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" },
		{ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" },
		{ "type": "line", "text": "What?", "speaker": "Vincent" },
		{ "type": "line", "text": "Tradução", "speaker": "Mia", "id": "145" },
		{ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" },
		{ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"},
	]

	for line in lines:
		compare_content(dialogue.get_content(), line)

	TranslationServer.set_locale("en")


func _test_options():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/options.json')


	var first_part = [
		{ "type": "line", "text": "what do you want to talk about?", "speaker": "npc" },
		{ "type": "options", "options": [{ "label": "Life" },{ "label": "The universe" }, { "label": "Everything else..." } ] },
	]

	var life_option = [
		{ "type": "line", "text": "I want to talk about life!", "speaker": "player" },
		{ "type": "line", "text": "Well! That's too complicated...", "speaker": "npc" },
	]

	for line in first_part:
		compare_content(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in life_option:
		compare_content(dialogue.get_content(), line)


func _test_blocks_and_diverts():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/diverts.json', 'initial_dialog')


	var initial_dialogue = [
		{ "type": "line", "text": "what do you want to talk about?", "speaker": "npc" },
		{ "type": "options", "options": [{ "label": "Life" },{ "label": "The universe" }, { "label": "Everything else..." }, { "label": "Goodbye!" }] },
	]

	var life_option = [
		{ "type": "line", "text": "I want to talk about life!", "speaker": "player" },
		{ "type": "line", "text": "Well! That's too complicated...", "speaker": "npc" },
		# back to initial dialogue
		{ "type": "options", "options": [{ "label": "The universe" }, { "label": "Everything else..." }, { "label": "Goodbye!" }] }
	]

	var everything_option = [
		{ "type": "line", "text": "What about everything else?", "speaker": "player" },
		{ "type": "line", "text": "I don't have time for this...", "speaker": "npc" },
		# back to initial dialogue
		{ "type": "options", "options": [{ "label": "The universe" }, { "label": "Goodbye!" }] }
	]

	var universe_option = [
		{ "type": "line", "text": "I want to talk about the universe!", "speaker": "player" },
		{ "type": "line", "text": "That's too complex!", "speaker": "npc" },
		# back to initial dialogue
		{ "type": "options", "options": [{ "label": "Goodbye!" }] }
	]

	var goodbye_option = [
		{ "type": "line", "text": "See you next time!", "speaker": "player" },
		null
	]

	for line in initial_dialogue:
		compare_content(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in life_option:
		compare_content(dialogue.get_content(), line)

	dialogue.choose(1)

	for line in everything_option:
		compare_content(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in universe_option:
		compare_content(dialogue.get_content(), line)

	dialogue.choose(0)

	for line in goodbye_option:
		compare_content(dialogue.get_content(), line)


func _test_variations():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/variations.json')

	var sequence = ["Hello", "Hi", "Hey"]
	var random_sequence = ["Hello", "Hi", "Hey"]
	var once = ["nested example", "here I am"]
	var random_cycle = ["multiline example do you think it works?", "yep"]


	for _i in range(4):
		dialogue.start()

		# sequence
		compare_var(
			dialogue.get_content().text,
			sequence[0]
		)

		if sequence.size() > 1:
			sequence.pop_front()

		# random sequence
		var rs = dialogue.get_content().text
		is_in_array(random_sequence, rs)
		if random_sequence.size() > 1:
			random_sequence.erase(rs)

		# once each
		if (once.size() != 0):
			var o = dialogue.get_content().text
			is_in_array(once, o)
			once.erase(o)

		# random cycle
		var rc = dialogue.get_content().text
		is_in_array(random_cycle, rc)
		random_cycle.erase(rc)
		if random_cycle.size() == 0:
			random_cycle = ["multiline example do you think it works?", "yep"]


func _test_logic():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/logic.json')
	compare_var(dialogue.get_content().text, "variable was initialized with 1")
	compare_var(dialogue.get_content().text, "setting multiple variables")
	compare_var(dialogue.get_content().text, "4 == 4.  3 == 3")
	compare_var(dialogue.get_content().text, "This is a block")
	compare_var(dialogue.get_content().text, "inside a condition")
	compare_var(dialogue.get_content(), null)

func _test_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/variables.json')
	compare_var(dialogue.get_content().text, "not")
	compare_var(dialogue.get_content().text, "equality")
	compare_var(dialogue.get_content().text, "alias equality")
	compare_var(dialogue.get_content().text, "trigger")
	compare_var(dialogue.get_content().text, "hey you")
	compare_var(dialogue.get_content().text, "hey {you}")
	compare_content(
		dialogue.get_content(),
		{ "type": "options", "options": [{ "label": "Life" }, { "label": "The universe" }] }
	)
	dialogue.choose(1)

	compare_content(dialogue.get_content(), { "type": "line", "text": "I want to talk about the universe!", "speaker": "player" })
	compare_content(dialogue.get_content(), { "type": "line", "text": "That's too complex!", "speaker": "npc" })
	compare_content(dialogue.get_content(), { "type": "line", "text": "I'm in trouble" })
	compare_var(dialogue.get_content(), null)
	compare_var(dialogue.get_variable('xx'), true)

func _test_set_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/variables.json')
	dialogue.set_variable('first_time', true)
	compare_var(dialogue.get_content().text, "what do you want to talk about?")
	dialogue.set_variable('first_time', false)
	dialogue.start()
	compare_var(dialogue.get_content().text, "not")


func _test_data_control():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/variations.json')

	compare_var(dialogue.get_content().text, "Hello")
	dialogue.start()
	compare_var(dialogue.get_content().text, "Hi")

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('res://sample/variations.json')
	dialogue2.load_data(dialogue.get_data())
	compare_var(dialogue2.get_content().text, "Hey")

	dialogue.clear_data()
	dialogue.start()
	compare_var(dialogue.get_content().text, "Hello")


#var pending_events = []

func _test_events():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/variables.json')
	dialogue.connect("event_triggered", self, "_on_event_triggered")
	dialogue.connect("variable_changed", self, "_on_variable_changed")

	add_pending_event({ "type": "variable", "name": "xx", "value": true })
	add_pending_event({ "type": "variable", "name": "first_time", "value": 2.0 })
	add_pending_event({ "type": "variable", "name": "a", "value": 3.0 })
	add_pending_event({ "type": "variable", "name": "b", "value": 3.0 })
	add_pending_event({ "type": "variable", "name": "c", "value": 3.0 })
	add_pending_event({ "type": "variable", "name": "d", "value": 3.0 })
	add_pending_event({ "type": "variable", "name": "a", "value": 6.0 })
	add_pending_event({ "type": "variable", "name": "a", "value": -10.0 })
	add_pending_event({ "type": "event", "name": "some_event" })
	add_pending_event({ "type": "event", "name": "another_event" })
	add_pending_event({ "type": "variable", "name": "a", "value": -14.0 })
	add_pending_event({ "type": "variable", "name": "b", "value": 1.0 })
	add_pending_event({ "type": "variable", "name": "c", "value": "hello" })
	add_pending_event({ "type": "variable", "name": "a", "value": 4.0 })
	add_pending_event({ "type": "variable", "name": "hp", "value": 5.0 })
	add_pending_event({ "type": "variable", "name": "s", "value": false })
	add_pending_event({ "type": "variable", "name": "x", "value": true })

	while true:
		var res = dialogue.get_content()
		if not res:
			break;
		if res.type == 'options':
			dialogue.choose(0)


func _on_variable_changed(name, value):
	for e in pending_events:
		if e.type == 'variable' and e.name == name and  typeof(e.value) == typeof(value) and  e.value == value:
			pending_events.erase(e)


func _on_event_triggered(event_name):
	for e in pending_events:
		if e.type == 'event' and e.name == event_name:
			pending_events.erase(e)


func _test_file_path_without_extension():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('res://sample/simple_lines')

	var lines = [
		{ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" },
		{ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" },
		{ "type": "line", "text": "What?", "speaker": "Vincent" },
		{ "type": "line", "text": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" },
		{ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" },
		{ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"},
	]

	for line in lines:
		compare_content(dialogue.get_content(), line)

func _test_uses_configured_dialogue_folder():
	var dialogue = ClydeDialogue.new()
	dialogue.dialogue_folder = 'res://sample'
	dialogue.load_dialogue('simple_lines')

	var lines = [
		{ "type": "line", "text": "Dinner at Jack Rabbit Slim's:" },
		{ "type": "line", "text": "Don’t you hate that?", "speaker": "Mia" },
		{ "type": "line", "text": "What?", "speaker": "Vincent" },
		{ "type": "line", "text": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" },
		{ "type": "line", "text": "I don’t know. That’s a good question.", "speaker": "Vincent" },
		{ "type": "line", "text": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"},
	]

	for line in lines:
		compare_content(dialogue.get_content(), line)
