extends RefCounted

signal variable_changed(name, value, previous_value)
signal event_triggered(event_name)

const Memory = preload("./Memory.gd")
const LogicInterpreter = preload("./LogicInterpreter.gd")

var _mem
var _logic
var _doc
var _stack = []
var _handlers = {}
var _anchors = {}
var _config

func init(document, interpreter_options = {}):
	_doc = document
	_doc._index = 1
	_mem = Memory.new()
	_mem.connect("variable_changed",Callable(self,"_trigger_variable_changed"))
	_logic = LogicInterpreter.new()
	_logic.init(_mem)

	_config = {
		"id_suffix_lookup_separator": interpreter_options.get("id_suffix_lookup_separator", "&"),
	}

	_initialise_blocks(_doc)
	_initialise_stack(_doc)
	_initialize_handlers()


func get_content():
	return _handle_next_node(_stack_head().current)


func choose(option_index):
	var node = _stack_head()

	if node.current.type == 'options':
		var content = _get_visible_options(node.current.content)

		if option_index >= content.size():
			printerr("Index %s not available." % option_index)
			return

		_mem.set_as_accessed(content[option_index]._index)
		_mem.set_internal_variable('OPTIONS_COUNT', _get_visible_options(node.current.content).size())
		content[option_index].content._index = content[option_index]._index;

		if content[option_index].type == 'action_content':
			content[option_index].content.content._index = content[option_index].content._index
			_handle_action(content[option_index]);
			_add_to_stack(content[option_index].content);
			_add_to_stack(content[option_index].content.content);
		else:
			_add_to_stack(content[option_index])
			_add_to_stack(content[option_index].content)
	else:
		printerr("Nothing to select")


func select_block(block_name = null):
	if block_name != null:
		_initialise_stack(_anchors[block_name])
	else:
		_initialise_stack(_doc)


func get_variable(name):
	return _mem.get_variable(name)


func set_variable(name, value):
	return _mem.set_variable(name, value)


func get_data():
	return _mem.get_all()


func load_data(data):
	return _mem.load_data(data)


func clear_data():
	return _mem.clear()


func _initialise_stack(root):
	_stack = [{
	"current": root,
	"content_index": -1
	}]


func _initialise_blocks(doc):
	for i in range(doc.blocks.size()):
		doc.blocks[i]._index = i + 2
		_anchors[doc.blocks[i].name] = doc.blocks[i]


func _stack_head():
	return _stack[_stack.size() - 1]


func _stack_pop():
	return _stack.pop_back()


func _add_to_stack(node):
	if _stack_head().current != node:
		_stack.push_back({
			"current": node,
			"content_index": -1
		})


func _generate_index():
	return (10 * _stack_head().current._index) + _stack_head().content_index


func _initialize_handlers():
	_handlers = {
		"document": _handle_document_node,
		"content": _handle_content_node,
		"line": _handle_line_node,
		"options": _handle_options_node,
		"option": _handle_option_node,
		"action_content": _handle_action_content_node,
		"conditional_content": _handle_conditional_content_node,
		"variations": _handle_variations_node,
		"block": _handle_block_node,
		"divert": _handle_divert_node,
		"assignments": _handle_assignments_node,
		"events": _handle_events_node,
	}


func _handle_document_node(_node):
	var node = _stack_head()
	var content_index = node.content_index + 1
	if content_index < node.current.content.size():
		node.content_index = content_index
		return _handle_next_node(node.current.content[content_index]);


func _handle_content_node(content_node):
	if content_node.get("_index") == null:
		content_node["_index"] = _generate_index()
	_add_to_stack(content_node)

	var node = _stack_head()
	var content_index = node.content_index + 1
	if content_index < node.current.content.size():
		node.content_index = content_index
		return _handle_next_node(node.current.content[content_index])
	_stack_pop()
	return _handle_next_node(_stack_head().current);


func _handle_line_node(line_node):
	if line_node.get("_index") == null:
		line_node["_index"] = _generate_index()

	return {
		"type": "line",
		"tags": line_node.get("tags"),
		"id": line_node.get("id"),
		"speaker": line_node.get("speaker"),
		"text": _replace_variables(_translate_text(line_node.get("id"), line_node.get("value"), line_node.get("id_suffixes")))
	}


func _handle_options_node(options_node):
	if options_node.get("_index") == null:
		options_node["_index"] = _generate_index()
		_mem.set_internal_variable('OPTIONS_COUNT', options_node.content.size())
	_add_to_stack(options_node)

	var options = _get_visible_options(options_node.content)
	_mem.set_internal_variable('OPTIONS_COUNT', options.size())

	if options.size() == 0:
		_stack_pop()
		return _handle_next_node(_stack_head().current)

	if options.size() == 1 and options[0].mode == 'fallback':
		choose(0)
		return _handle_next_node(_stack_head().current)

	return {
		"type": "options",
		"speaker": options_node.get("speaker"),
		"id": options_node.get("id"),
		"tags": options_node.get("tags"),
		"name": _replace_variables(_translate_text(options_node.get("id"), options_node.get("name"), options_node.get("id_suffixes"))),
		"options": options.map(func(e): return _map_option(e, options.find(e))),
	}


func _get_visible_options(options):
	return options.map(func (e):
		return _prepare_option(e, options.find(e))
	).filter(_check_if_option_not_accessed)


func _prepare_option(option, index):
	if option.get("index") == null:
		option._index = _generate_index() * 100 + index

	if option.type == 'conditional_content':
		option.content._index = option._index;
		if _logic.check_condition(option.conditions):
			return _prepare_option(option.content, index)
		return

	if option.type == 'action_content':
		option.content._index = option._index
		option.mode = option.content.mode
		var content = _prepare_option(option.content, index)
		if content == null:
			return

	return option


func _check_if_option_not_accessed(option):
	return option != null and not (option.mode == 'once' and _mem.was_already_accessed(option._index))


func _map_option(option, _index):
	var o = option if option.type == 'option' else option.content
	return {
		"speaker": o.get("speaker"),
		"id": o.get("id"),
		"tags": o.get("tags"),
		"label": _replace_variables(_translate_text(o.get("id"), o.get("name"), o.get("id_suffixes"))),
	}


func _handle_option_node(_option_node):
	# this is called when the contents inside the option
	# were read. option list default behavior is to quit
	# so we need to remove both option and option list from the stack.
	_stack_pop()
	_stack_pop()
	return _handle_next_node(_stack_head().current);


func _handle_action_content_node(action_node):
	_handle_action(action_node)
	return _handle_next_node(action_node.content)


func _handle_action(action_node):
	if action_node.action.type == 'events':
		for event in action_node.action.events:
			emit_signal("event_triggered", event.name)
	else:
		for assignment in action_node.action.assignments:
			_logic.handle_assignment(assignment)


func _handle_conditional_content_node(conditional_node, fallback_node = _stack_head().current):
	if _logic.check_condition(conditional_node.conditions):
		return _handle_next_node(conditional_node.content);
	return _handle_next_node(fallback_node)


func _handle_variations_node(variations, attempt = 0):
	if variations.get("_index") == null:
		variations["_index"] = _generate_index()
		for index in range(variations.content.size()):
			var c = variations.content[index]
			c._index = _generate_index() * 100 + index

	var next = _handle_variation_mode(variations)
	if next == -1 or attempt > variations.content.size():
		return _handle_next_node(_stack_head().current)

	if variations.content[next].content.size() == 1 and variations.content[next].content[0].type == 'conditional_content':
		if not _logic.check_condition(variations.content[next].content[0].conditions):
			return _handle_variations_node(variations, attempt + 1)

	return _handle_next_node(variations.content[next]);


func _handle_block_node(block):
	_add_to_stack(block)
	var node = _stack_head()
	var content_index = node.content_index + 1

	if content_index < node.current.content.content.size():
		node.content_index = content_index
		return _handle_next_node(node.current.content.content[content_index]);


func _handle_divert_node(divert):
	if divert.target == '<parent>':
		var target_parents = ['document', 'block', 'option', 'options']

		while not target_parents.has(_stack_head().current.type):
			_stack_pop()

		if _stack.size() > 1:
			_stack_pop()
			return _handle_next_node(_stack_head().current)
	elif divert.target == '<end>':
		_initialise_stack(_doc)
		_stack_head().content_index = _stack_head().current.content.size();
	else:
		return _handle_next_node(_anchors[divert.target])


func _handle_assignments_node(assignment_node):
	for assignment in assignment_node.assignments:
		_logic.handle_assignment(assignment)
	return _handle_next_node(_stack_head().current);


func _handle_events_node(events):
	for event in events.events:
		emit_signal("event_triggered", event.name)

	return _handle_next_node(_stack_head().current);


func _handle_next_node(node):
	if _handlers.has(node.type):
		return _handlers[node.type].call(node)
	else:
		printerr("Unkown node type '%s'" % node.type)


func _translate_text(key, text, id_suffixes = null):
	if key == null:
		return text

	if id_suffixes != null:
		var lookup_key = key
		for ids in id_suffixes:
			var value = _mem.get_variable(ids)
			if value != null:
				lookup_key += "%s%s" % [_config.id_suffix_lookup_separator, value]
		var position = tr(lookup_key)

		if position != lookup_key:
			return position

	var position = tr(key)
	if position == key:
		return text
	return position


func _replace_variables(text):
	if text == null or text == "":
		return text
	var regex = RegEx.new()
	regex.compile("\\%(?<variable>[A-z0-9]*)\\%")
	for result in regex.search_all(text):
		var value = _mem.get_variable(result.get_string("variable"))
		text = text.replace(result.get_string(), str(value) if value != null else "")

	return text


func _handle_variation_mode(variations):
	match variations.mode:
		"cycle":
			return _handle_cycle_variation(variations)
		"sequence":
			return _handle_sequence_variation(variations)
		"once":
			return _handle_once_variation(variations)
		"shuffle":
			return _handle_shuffle_variation(variations)
		"shuffle sequence":
			return _handle_shuffle_variation(variations, "sequence")
		"shuffle once":
			return _handle_shuffle_variation(variations, "once")
		"shuffle cycle":
			return _handle_shuffle_variation(variations, "cycle")
	printerr("Variation mode '%s' is unknown" % variations.mode)


func _handle_cycle_variation(variations):
	var current = _mem.get_internal_variable(variations._index, -1);
	if current < variations.content.size() - 1:
		current += 1;
	else:
		current = 0

	_mem.set_internal_variable(variations._index, current)
	return current;


func _handle_once_variation(variations):
	var current = _mem.get_internal_variable(variations._index, -1);
	var index = current + 1;
	if index <= variations.content.size() - 1:
		_mem.set_internal_variable(variations._index, index)
		return index

	return -1;


func _handle_sequence_variation(variations):
	var current = _mem.get_internal_variable(variations._index, -1)
	if current < variations.content.size() - 1:
		current += 1;
		_mem.set_internal_variable(variations._index, current)

	return current;


func _handle_shuffle_variation(variations, mode = 'cycle'):
	var SHUFFLE_VISITED_KEY = "%s_shuffle_visited" % variations._index;
	var LAST_VISITED_KEY = "%s_last_index" % variations._index;
	var visited_items = _mem.get_internal_variable(SHUFFLE_VISITED_KEY, []);
	var remaining_options = []
	for o in variations.content:
		if not visited_items.has(o._index):
			remaining_options.push_back(o)

	if remaining_options.size() == 0:
		if mode == 'once':
			return -1

		if mode == 'cycle':
			_mem.set_internal_variable(SHUFFLE_VISITED_KEY, []);
			return _handle_shuffle_variation(variations, mode)
		return _mem.get_internal_variable(LAST_VISITED_KEY, -1);

	randomize()
	var random = randi() % remaining_options.size()
	var index = variations.content.find(remaining_options[random]);

	visited_items.push_back(remaining_options[random]._index);

	_mem.set_internal_variable(LAST_VISITED_KEY, index);
	_mem.set_internal_variable(SHUFFLE_VISITED_KEY, visited_items);

	return index;


func _trigger_variable_changed(name, value, previous_value):
	emit_signal("variable_changed", name, value, previous_value)
