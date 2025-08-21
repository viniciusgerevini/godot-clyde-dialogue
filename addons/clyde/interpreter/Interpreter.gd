extends RefCounted

signal variable_changed(name: String, value: Variant, previous_value: Variant)
signal event_triggered(event_name: String, parameters: Array)

const Memory = preload("./Memory.gd")
const LogicInterpreter = preload("./LogicInterpreter.gd")

const CONTENT_TYPE_LINE = "line"
const CONTENT_TYPE_OPTIONS = "options"
const CONTENT_TYPE_END = "end"

var _mem
var _logic
var _doc
var _doc_stack = []
var _stack = []
var _handlers = {}
var _anchors = {}
var _config
var _doc_anchors = {}
var _loaded_docs = {}

var _file_loader: Callable

func init(document: Dictionary, interpreter_options: Dictionary = {}) -> void:
	_doc = document
	_doc_stack.push_back(_doc)
	_doc._index = "r"
	_mem = Memory.new()
	_mem.variable_changed.connect(_trigger_variable_changed)
	_logic = LogicInterpreter.new()
	_logic.init(_mem)

	_config = {
		"id_suffix_lookup_separator": interpreter_options.get("id_suffix_lookup_separator", "&"),
		"include_hidden_options": interpreter_options.get("include_hidden_options", false)
	}

	_initialise_blocks(_doc)
	_initialise_links(_doc)
	_initialise_stack(_doc)
	_initialize_handlers()


func get_content() -> Dictionary:
	return _handle_next_node(_stack_head().current)


func choose(option_index: int) -> void:
	var node = _stack_head()

	if node.current.type == 'options':
		var content = _get_visible_options(node.current.content)

		if option_index >= content.size():
			printerr("Index %s not available." % option_index)
			return

		if (not content[option_index].get("is_visible", true)):
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


func select_block(block_name: String = "") -> void:
	if block_name != "":
		_initialise_stack(_doc.anchors[block_name])
	else:
		_initialise_stack(_doc)


func has_block(block_name: String) -> bool:
	return block_name in _doc.anchors


func get_variable(name: String) -> Variant:
	return _mem.get_variable(name)


func set_variable(name: String, value: Variant) -> Variant:
	return _mem.set_variable(name, value)


func on_external_variable_fetch(callback: Callable) -> void:
	_mem.on_external_variable_fetch(callback)


func on_external_variable_update(callback: Callable) -> void:
	_mem.on_external_variable_update(callback)


func get_data() -> Dictionary:
	return _mem.get_all()


func load_data(data: Dictionary) -> void:
	_mem.load_data(data)


func clear_data() -> void:
	_mem.clear()


func _initialise_stack(root: Dictionary) -> void:
	_stack = [{
	"current": root,
	"content_index": -1
	}]


func _initialise_blocks(doc: Dictionary) -> void:
	doc["anchors"] = {}
	for i in range(doc.blocks.size()):
		doc.blocks[i]._index = "b_%s" % doc.blocks[i].name
		doc.anchors[doc.blocks[i].name] = doc.blocks[i]
	_anchors = doc.anchors


func _initialise_links(doc: Dictionary) -> void:
	_doc_anchors = doc.get("links", {})


func _stack_head() -> Dictionary:
	return _stack[_stack.size() - 1]


func _stack_pop() -> Dictionary:
	return _stack.pop_back()


func _add_to_stack(node: Dictionary) -> void:
	if _stack_head().current != node:
		_stack.push_back({
			"current": node,
			"content_index": -1
		})


func _generate_index() -> String:
	return "%s_%s" % [_stack_head().current._index, _stack_head().content_index]


func _initialize_handlers() -> void:
	_handlers = {
		"document": _handle_document_node,
		"linked_document": _handle_linked_doc,
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
		"match": _handle_match_block_node,
	}


func _handle_document_node(doc_node: Dictionary) -> Dictionary:
	var node = _stack_head()
	_anchors = doc_node.anchors
	_doc_anchors = doc_node.get("links", [])
	var content_index = node.content_index + 1
	if content_index < node.current.content.size():
		node.content_index = content_index
		return _handle_next_node(node.current.content[content_index]);

	return { "type": CONTENT_TYPE_END }


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

	var line = {
		"type": CONTENT_TYPE_LINE,
		"tags": line_node.get("tags"),
		"id": line_node.get("id"),
		"speaker": line_node.get("speaker"),
		"text": _replace_variables(_translate_text(line_node.get("id"), line_node.get("value"), line_node.get("id_suffixes")))
	}
	if line_node.has("meta"):
		line.meta = line_node.meta
	return line


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

	# fallback only works when hidden options are not shown
	if options.size() == 1 and not _config.include_hidden_options and options[0].mode == "fallback":
		choose(0)
		return _handle_next_node(_stack_head().current)

	var o = {
		"type": CONTENT_TYPE_OPTIONS,
		"speaker": options_node.get("speaker"),
		"id": options_node.get("id"),
		"tags": options_node.get("tags"),
		"text": _replace_variables(_translate_text(options_node.get("id"), options_node.get("name"), options_node.get("id_suffixes"))),
		"options": options.map(func(e): return _map_option(e, options.find(e), _config.include_hidden_options)),
	}
	if options_node.has("meta"):
		o.meta = options_node.meta
	return o


func _get_visible_options(options):
	return options.map(func (e):
		return _prepare_option(e, options.find(e), _config.include_hidden_options)
	).filter(_check_if_option_not_accessed)


func _prepare_option(option, index, should_include_hidden = false, is_visible = true):
	if option.get("index") == null:
		option._index = "%s_%s" % [_generate_index(), index]

	if option.type == 'conditional_content':
		option.content._index = option._index;

		var is_visible_option = !!_logic.check_condition(option.conditions)
		if should_include_hidden or is_visible_option:
			return _prepare_option(option.content, index, should_include_hidden, is_visible_option)
		return null

	if option.type == 'action_content':
		option.content._index = option._index
		option.mode = option.content.mode
		var content = _prepare_option(option.content, index, should_include_hidden)
		if content == null:
			return null

	option.is_visible = is_visible

	return option


func _check_if_option_not_accessed(option):
	return option != null and not (option.mode == 'once' and _mem.was_already_accessed(option._index))


func _map_option(option, _index, include_visibility_prop = false):
	var o = option if option.type == 'option' else option.content
	var result = {
		"speaker": o.get("speaker"),
		"id": o.get("id"),
		"tags": o.get("tags"),
		"text": _replace_variables(_translate_text(o.get("id"), o.get("name"), o.get("id_suffixes"))),
		"visited": _mem.was_already_accessed(option._index),
	}

	if include_visibility_prop:
		result.is_visible = o.get("is_visible", false)
	return result


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
		_trigger_events(action_node.action)
	else:
		for assignment in action_node.action.assignments:
			_logic.handle_assignment(assignment)


func _trigger_events(events):
	for event in events.events:
		var parameters = []

		if event.get("params", null) != null:
			parameters = event.params.map(_logic.get_node_value)

		event_triggered.emit(event.name, parameters)


func _handle_conditional_content_node(conditional_node, fallback_node = _stack_head().current):
	if _logic.check_condition(conditional_node.conditions):
		return _handle_next_node(conditional_node.content);
	return _handle_next_node(fallback_node)


func _handle_match_block_node(node):
	var condition_value = _logic.get_node_value(node.condition)

	for branch in node.branches:
		var branch_value = _logic.get_node_value(branch.check)
		if typeof(branch_value) != typeof(condition_value):
			continue
		if condition_value == branch_value:
			return _handle_next_node(branch.content)

	if node.default_branch != null:
		return _handle_next_node(node.default_branch)

	return _handle_next_node(_stack_head().current)


func _handle_variations_node(variations, attempt = 0):
	if variations.get("_index") == null:
		variations["_index"] = _generate_index()
		for index in range(variations.content.size()):
			var c = variations.content[index]
			c._index = "%s_%s" % [_generate_index(), index]

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

	return { "type": CONTENT_TYPE_END }


func _handle_divert_node(divert):
	if divert.target is Dictionary:
		return _divert_to_linked_doc(divert.target)

	if divert.target == '<parent>':
		var target_parents = ['document', 'block', 'option', 'options', 'linked_document']

		while not target_parents.has(_stack_head().current.type):
			_stack_pop()

		if _stack.size() > 1:
			_stack_pop()
			return _handle_next_node(_stack_head().current)

		return { "type": CONTENT_TYPE_END }

	if divert.target == '<end>':
		_initialise_stack(_doc)
		_stack_head().content_index = _stack_head().current.content.size();
		return { "type": CONTENT_TYPE_END }

	return _handle_next_node(_anchors[divert.target])


func _divert_to_linked_doc(link: Dictionary):
	if not _doc_anchors.has(link.link):
		push_error("Could not divert to '%s'. Link not found." % link.link)
		return

	var doc_path = _doc_anchors[link.link]

	var doc_node

	var actual_path = doc_path

	if doc_path.begins_with("./") or doc_path.begins_with("../"):
		actual_path = _get_path_relative_to_current_doc(doc_path)

	if _loaded_docs.has(actual_path):
		doc_node = _loaded_docs[actual_path]
	else:
		var load_path
		var doc = _file_loader.call(actual_path)
		if doc.is_empty():
			push_error("Could not load file '%s'" % actual_path)
			return { "type": CONTENT_TYPE_END }

		doc._index = link.link
		doc.type = "linked_document"
		_initialise_blocks(doc)
		doc_node = doc
		_loaded_docs[actual_path] = doc

	_doc_stack.push_back(doc_node)

	_anchors = doc_node.anchors
	_doc_anchors = doc_node.get("links", {})

	_add_to_stack(_loaded_docs[actual_path])

	if link.block == "":
		return _handle_document_node(_loaded_docs[actual_path])
	else:
		return _handle_next_node(_anchors[link.block])


func _handle_linked_doc(doc: Dictionary):
	_doc_stack.pop_back()
	var doc_node = _doc_stack[_doc_stack.size() - 1]
	_anchors = doc_node.anchors
	_doc_anchors = doc_node.links
	_stack_pop()
	return _handle_next_node(_stack_head().current)


func _handle_assignments_node(assignment_node):
	for assignment in assignment_node.assignments:
		_logic.handle_assignment(assignment)
	return _handle_next_node(_stack_head().current);


func _handle_events_node(events):
	_trigger_events(events)
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
	var regex = RegEx.create_from_string("\\%(?<variable>[A-z0-9@]*)\\%")
	for result in regex.search_all(text):
		var value = _mem.get_variable(result.get_string("variable"))
		text = text.replace(result.get_string(), _parse_variable_value_for_print(value) if value != null else "")

	return text

func _parse_variable_value_for_print(value) -> String:
	# all numbers are saved as float. For backwards compatibility and simplification, when a number
	# does not have a relevant decimal part (e.g. 5.0), it should be printed as an int (e.g 5)
	if typeof(value) == TYPE_FLOAT:
		if fmod(value, 1.0) == 0:
			return "%d" % value;
	return str(value)


func _handle_variation_mode(variations):
	match variations.mode:
		"cycle":
			return _handle_cycle_variation(variations)
		"sequence":
			return _handle_sequence_variation(variations)
		"once":
			return _handle_once_variation(variations)
		"shuffle":
			return _handle_real_shuffle_variation(variations)
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
	var SHUFFLE_VISITED_KEY = "%s_shuffle_visited" % variations._index
	var LAST_VISITED_KEY = "%s_last_index" % variations._index
	var visited_items = _mem.get_internal_variable(SHUFFLE_VISITED_KEY, [])
	var remaining_options = []
	for o in variations.content:
		if not visited_items.has(o._index):
			remaining_options.push_back(o)

	if remaining_options.size() == 0:
		if mode == 'once':
			return -1

		if mode == 'cycle':
			_mem.set_internal_variable(SHUFFLE_VISITED_KEY, [])
			return _handle_shuffle_variation(variations, mode)
		return _mem.get_internal_variable(LAST_VISITED_KEY, -1)

	randomize()
	var random = randi() % remaining_options.size()
	var index = variations.content.find(remaining_options[random])

	visited_items.push_back(remaining_options[random]._index)

	_mem.set_internal_variable(LAST_VISITED_KEY, index);
	_mem.set_internal_variable(SHUFFLE_VISITED_KEY, visited_items)

	return index;


func _handle_real_shuffle_variation(variations):
	randomize()
	return randi() % variations.content.size()


func _trigger_variable_changed(name: String, value: Variant, previous_value: Variant) -> void:
	variable_changed.emit(name, value, previous_value)


func set_file_loader(file_loader: Callable) -> void:
	_file_loader = file_loader


func _get_path_relative_to_current_doc(doc_path: String) -> String:
	var current_doc = _doc_stack[_doc_stack.size() - 1]
	var parent: String = current_doc.doc_path.get_base_dir()
	return parent.path_join(doc_path)
