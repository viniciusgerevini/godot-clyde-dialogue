extends RefCounted

signal parsing_failure(result: Dictionary)

const Lexer = preload("./Lexer.gd")
const TokenWalker = preload("./TokenWalker.gd")

var _is_multiline_enabled = true

const _variations_modes = ['sequence', 'once', 'cycle', 'shuffle', 'shuffle sequence', 'shuffle once', 'shuffle cycle' ]

const operators = {
	Lexer.TOKEN_AND: { "precedence": 1, "associative": 'LEFT' },
	Lexer.TOKEN_OR: { "precedence": 1, "associative": 'LEFT' },
	Lexer.TOKEN_EQUAL: { "precedence": 2, "associative": 'LEFT' },
	Lexer.TOKEN_NOT_EQUAL: { "precedence": 2, "associative": 'LEFT' },
	Lexer.TOKEN_GREATER: { "precedence": 2, "associative": 'LEFT' },
	Lexer.TOKEN_LESS: { "precedence": 2, "associative": 'LEFT' },
	Lexer.TOKEN_GE: { "precedence": 2, "associative": 'LEFT' },
	Lexer.TOKEN_LE: { "precedence": 2, "associative": 'LEFT' },
	Lexer.TOKEN_PLUS: { "precedence": 3, "associative": 'LEFT' },
	Lexer.TOKEN_MINUS: { "precedence": 3, "associative": 'LEFT' },
	Lexer.TOKEN_MOD: { "precedence": 4, "associative": 'LEFT' },
	Lexer.TOKEN_MULT: { "precedence": 5, "associative": 'LEFT' },
	Lexer.TOKEN_DIV: { "precedence": 5, "associative": 'LEFT' },
	Lexer.TOKEN_POWER: { "precedence": 7, "associative": 'RIGHT' },
}

const _assignment_operators = {
	Lexer.TOKEN_ASSIGN: 'assign',
	Lexer.TOKEN_ASSIGN_SUM: 'assign_sum',
	Lexer.TOKEN_ASSIGN_SUB: 'assign_sub',
	Lexer.TOKEN_ASSIGN_MULT: 'assign_mult',
	Lexer.TOKEN_ASSIGN_DIV: 'assign_div',
	Lexer.TOKEN_ASSIGN_POW: 'assign_pow',
	Lexer.TOKEN_ASSIGN_MOD: 'assign_mod',
	Lexer.TOKEN_ASSIGN_INIT: 'assign_init',
}

var _tokens

var _include_meta = false

func parse(doc, include_meta: bool = false):
	_include_meta = include_meta
	var lexer = Lexer.new()
	_tokens = TokenWalker.new()
	_tokens.set_tokens(lexer.init(doc))
	_tokens.unexpected_token_detected.connect(_on_unexpected_token)

	#var l = Lexer.new()
	#print(l.init(doc).get_all())

	var result = _document()
	if _tokens.has_next():
		_tokens.consume([ Lexer.TOKEN_EOF ])

	return result


func _document():
	var expected = [
		Lexer.TOKEN_EOF,
		Lexer.TOKEN_SPEAKER,
		Lexer.TOKEN_TEXT,
		Lexer.TOKEN_OPTION,
		Lexer.TOKEN_STICKY_OPTION,
		Lexer.TOKEN_FALLBACK_OPTION,
		Lexer.TOKEN_DIVERT,
		Lexer.TOKEN_DIVERT_PARENT,
		Lexer.TOKEN_BRACKET_OPEN,
		Lexer.TOKEN_BRACE_OPEN,
		Lexer.TOKEN_LINE_BREAK,
		Lexer.TOKEN_BLOCK,
		Lexer.TOKEN_LINK_FILE,
	]
	var next = _tokens.peek(expected)

	if next == null:
		_tokens._wrong_token_error(next, expected)
		return

	var doc = DocumentNode()

	if next.token == Lexer.TOKEN_EOF:
		return doc

	# links are always at the beginnig of the file
	if next.token == Lexer.TOKEN_LINK_FILE:
		doc.links = _links()

	# if a block token is next, it's because there is not
	# default block
	if _tokens.has_next([Lexer.TOKEN_BLOCK]):
		doc.blocks = _blocks()
		return doc

	doc.content =  [ContentNode(_lines())]

	if _tokens.has_next([Lexer.TOKEN_BLOCK]):
		doc.blocks = _blocks()

	return doc


func _links():
	var links = {}
	while _tokens.has_next([Lexer.TOKEN_LINK_FILE]):
		_tokens.consume([Lexer.TOKEN_LINK_FILE])
		links[_tokens.current_token.value.name] = _tokens.current_token.value.path

	return links

func _blocks():
	_tokens.consume([Lexer.TOKEN_BLOCK])
	var blockToken = _tokens.current_token
	var blocks =  [
		BlockNode(blockToken.value, ContentNode(_lines()), _meta(blockToken))
	]

	while _tokens.has_next([Lexer.TOKEN_BLOCK]):
		blocks = blocks + _blocks()

	return blocks


func _lines():
	var acceptable_next = [
		Lexer.TOKEN_SPEAKER,
		Lexer.TOKEN_TEXT,
		Lexer.TOKEN_OPTION,
		Lexer.TOKEN_STICKY_OPTION,
		Lexer.TOKEN_FALLBACK_OPTION,
		Lexer.TOKEN_DIVERT,
		Lexer.TOKEN_DIVERT_PARENT,
		Lexer.TOKEN_BRACKET_OPEN,
		Lexer.TOKEN_BRACE_OPEN,
		Lexer.TOKEN_LINE_BREAK,
	]
	var lines
	var tk = _tokens.peek(acceptable_next)

	if tk == null:
		return []

	if tk.token == Lexer.TOKEN_SPEAKER or tk.token == Lexer.TOKEN_TEXT:
		_tokens.consume([ Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT ])

		if tk.token == Lexer.TOKEN_SPEAKER and _tokens.has_next([Lexer.TOKEN_INDENT]):
			lines = _lines_with_speaker()
		else:
			var line = _line()
			if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
				_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
				lines = [_line_with_action(line)]
			else:
				lines = [line]
	elif tk.token == Lexer.TOKEN_OPTION or tk.token == Lexer.TOKEN_STICKY_OPTION or tk.token == Lexer.TOKEN_FALLBACK_OPTION:
		lines = [_options()]
	elif tk.token == Lexer.TOKEN_DIVERT or tk.token == Lexer.TOKEN_DIVERT_PARENT:
		lines = [_divert()]
	elif tk.token == Lexer.TOKEN_BRACKET_OPEN:
			_tokens.consume([ Lexer.TOKEN_BRACKET_OPEN ])
			lines = [_variations()]
	elif tk.token == Lexer.TOKEN_LINE_BREAK or tk.token == Lexer.TOKEN_BRACE_OPEN:
		if tk.token == Lexer.TOKEN_LINE_BREAK:
			_tokens.consume([ Lexer.TOKEN_LINE_BREAK ])

		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])

		if _tokens.has_next([Lexer.TOKEN_KEYWORD_MATCH]):
			lines = [_match_block()]
		elif _tokens.has_next([Lexer.TOKEN_KEYWORD_SET, Lexer.TOKEN_KEYWORD_TRIGGER]):
			lines = [_line_with_action()]
		else:
			if _tokens.has_next([Lexer.TOKEN_KEYWORD_WHEN]):
				_tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])
			lines = [_conditional_line()]


	if _tokens.has_next(acceptable_next):
		lines = lines + _lines()

	return lines


func _line():
	return _dialogue_line()


func _dialogue_line():
	match _tokens.current_token.token:
		Lexer.TOKEN_SPEAKER:
			return _line_with_speaker()
		Lexer.TOKEN_TEXT:
			return _text_line()


func _lines_with_speaker():
	var speaker_token = _tokens.current_token
	var lines = []
	_tokens.consume([Lexer.TOKEN_INDENT])

	while not _tokens.has_next([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF]):
		_tokens.consume([Lexer.TOKEN_TEXT])
		var line = _text_line()
		line.speaker = speaker_token.value;

		if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
			lines.push_back(_line_with_action(line))
		else:
			lines.push_back(line)

	if _tokens.has_next([Lexer.TOKEN_DEDENT]):
		_tokens.consume([Lexer.TOKEN_DEDENT])

	return lines


func _line_with_speaker():
	var value = _tokens.current_token.value
	_tokens.consume([Lexer.TOKEN_TEXT])
	var line = _dialogue_line()
	line.speaker =  value
	return line


func _text_line():
	var value = _tokens.current_token.value
	var text_column = _tokens.current_token.column
	var text_line = _tokens.current_token.line
	var next = _tokens.peek([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
	var line

	if next != null:
		_tokens.consume([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
		line = _line_with_metadata()
		line.value = value
	else:
		line = LineNode(value)


	if _is_multiline_enabled && _tokens.has_next([Lexer.TOKEN_INDENT]):
		_tokens.consume([Lexer.TOKEN_INDENT])

		if _tokens.has_next([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION, Lexer.TOKEN_FALLBACK_OPTION]):
			var options = _options()
			options.id = line.id
			options.name = line.value
			options.tags = line.tags
			options.id_suffixes = line.id_suffixes
			line = options
		else:
			while not _tokens.has_next([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF]):
				_tokens.consume([Lexer.TOKEN_TEXT])
				var next_line = _text_line()
				line.value += " %s" % next_line.value
				if next_line.id != null:
					line.id = next_line.id
					line.id_suffixes = next_line.id_suffixes

				if not next_line.tags.is_empty():
					line.tags = next_line.tags

			_tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])

	return _with_optional_meta(line, { "line": text_line, "column": text_column })


func _line_with_metadata():
	match _tokens.current_token.token:
		Lexer.TOKEN_LINE_ID:
			return _line_with_id()
		Lexer.TOKEN_TAG:
			return _line_with_tags()


func _line_with_id():
	var value = _tokens.current_token.value
	var suffixes

	if _tokens.has_next([Lexer.TOKEN_ID_SUFFIX]):
		suffixes = _id_suffixes()


	if _tokens.has_next([Lexer.TOKEN_TAG]):
		_tokens.consume([Lexer.TOKEN_TAG])
		var line = _line_with_tags()
		line.id = value
		line.id_suffixes = suffixes
		return line

	return LineNode(null, null, value, [], suffixes)


func _id_suffixes():
	var suffixes = []
	while _tokens.has_next([Lexer.TOKEN_ID_SUFFIX]):
		var token = _tokens.consume([Lexer.TOKEN_ID_SUFFIX])
		suffixes.push_back(token.value)
	return suffixes


func _line_with_tags():
	var value = _tokens.current_token.value
	var next = _tokens.has_next([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
	if next:
		_tokens.consume([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
		var line = _line_with_metadata()
		line.tags.push_front(value)
		return line

	return LineNode(null, null, null, [value])


func _options():
	var tk = _tokens.peek()
	var options = _with_optional_meta(OptionsNode([]), { "line": tk.line, "column": tk.column })

	while _tokens.has_next([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION, Lexer.TOKEN_FALLBACK_OPTION]):
		options.content.push_back(_option())

	if _tokens.has_next([ Lexer.TOKEN_DEDENT ]):
		_tokens.consume([ Lexer.TOKEN_DEDENT ])

	return options

var option_types = {
	Lexer.TOKEN_OPTION: 'once',
	Lexer.TOKEN_STICKY_OPTION: 'sticky',
	Lexer.TOKEN_FALLBACK_OPTION: 'fallback',
}

func _option():
	_tokens.consume([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION, Lexer.TOKEN_FALLBACK_OPTION])
	var type = option_types[_tokens.current_token.token]
	var acceptable_next = [Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT, Lexer.TOKEN_INDENT, Lexer.TOKEN_ASSIGN, Lexer.TOKEN_BRACE_OPEN]
	var lines = []
	var main_item
	var include_label_as_content = false
	var root
	var wrapper

	_tokens.consume(acceptable_next)

	if _tokens.current_token.token == Lexer.TOKEN_ASSIGN:
		include_label_as_content = true
		_tokens.consume(acceptable_next)

	if _tokens.current_token.token == Lexer.TOKEN_BRACE_OPEN:
		var block = _nested_logic_block()
		root = block.root
		wrapper = block.wrapper
		_tokens.consume(acceptable_next)

	if _tokens.current_token.token == Lexer.TOKEN_SPEAKER or _tokens.current_token.token == Lexer.TOKEN_TEXT:
			_is_multiline_enabled = false
			main_item = _line()
			_is_multiline_enabled = true
			if include_label_as_content:
				lines.push_back(main_item)

	if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		var block = _nested_logic_block()

		if root == null:
			root = block.root
			wrapper = block.wrapper
		else:
			wrapper.content = block.wrapper
			wrapper = block.wrapper

		_tokens.consume([Lexer.TOKEN_LINE_BREAK])


	if _tokens.current_token.token == Lexer.TOKEN_INDENT || _tokens.has_next([Lexer.TOKEN_INDENT]):
		if _tokens.current_token.token != Lexer.TOKEN_INDENT:
			_tokens.consume([Lexer.TOKEN_INDENT])

		lines = lines + _lines()
		if main_item == null:
			main_item = lines[0]

		_tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])


	var node = OptionNode(
		ContentNode(lines),
		type,
		main_item.value,
		main_item.id,
		main_item.speaker,
		main_item.tags,
		main_item.id_suffixes
	)

	if root:
		wrapper.content = node
		return root

	return node


func _nested_logic_block():
	var root
	var wrapper
	while _tokens.current_token.token == Lexer.TOKEN_BRACE_OPEN:
		if root == null:
			root = _logic_block()
			wrapper = root
		else:
			var next = _logic_block()
			wrapper.content = next
			wrapper = next

		if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])

	return {
		"root": root,
		"wrapper": wrapper
	}


func _divert():
	_tokens.consume([ Lexer.TOKEN_DIVERT, Lexer.TOKEN_DIVERT_PARENT ])
	var divert = _tokens.current_token

	var token
	match divert.token:
		Lexer.TOKEN_DIVERT:
			token = DivertNode(divert.value)
		Lexer.TOKEN_DIVERT_PARENT:
			token = DivertNode('<parent>')

	if _tokens.has_next([Lexer.TOKEN_LINE_BREAK]):
		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
		return token

	if _tokens.has_next([Lexer.TOKEN_EOF]):
		return  token

	if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		token = _line_with_action(token)


	return token


func _variations():
	var variations = VariationsNode('sequence')

	if _tokens.has_next([Lexer.TOKEN_VARIATIONS_MODE]):
		var mode = _tokens.consume([Lexer.TOKEN_VARIATIONS_MODE])
		if !_variations_modes.has(mode.value):
			printerr("Wrong variation mode set \"%s\" on line %s column %s. Valid modes: %s." % [
				mode.value,
				_tokens.current_token.line,
				_tokens.current_token.column,
				_variations_modes
			])
			return

		variations.mode = mode.value

	while _tokens.has_next([Lexer.TOKEN_INDENT, Lexer.TOKEN_MINUS]):
		if _tokens.has_next([Lexer.TOKEN_INDENT]):
			_tokens.consume([Lexer.TOKEN_INDENT])
			continue

		_tokens.consume([Lexer.TOKEN_MINUS])

		var starts_next_line = false
		if _tokens.has_next([Lexer.TOKEN_INDENT]):
			_tokens.consume([Lexer.TOKEN_INDENT])
			starts_next_line = true


		variations.content.push_back(ContentNode(_lines()))
		if starts_next_line:
			var lastVariation = variations.content[variations.content.size() - 1].content
			var lastContent = lastVariation[lastVariation.size() - 1]
			if lastContent.type != 'options':
				_tokens.consume([Lexer.TOKEN_DEDENT])

		if _tokens.has_next([Lexer.TOKEN_DEDENT]):
			_tokens.consume([Lexer.TOKEN_DEDENT])

	_tokens.consume([Lexer.TOKEN_BRACKET_CLOSE])

	return variations


func _line_with_action(line = null):
	var token = _tokens.peek([
		Lexer.TOKEN_KEYWORD_SET,
		Lexer.TOKEN_KEYWORD_TRIGGER,
	])
	var expression = _logic_element()

	if line:
		var content = line

		if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
			content = _line_with_action(line)


		if _tokens.has_next([Lexer.TOKEN_LINE_BREAK]):
			_tokens.consume([Lexer.TOKEN_LINE_BREAK])


		if token == null or token.token == Lexer.TOKEN_KEYWORD_WHEN:
			return ConditionalContentNode(expression, content)

		return ActionContentNode(expression, content)


	if _tokens.has_next([Lexer.TOKEN_LINE_BREAK]):
		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
		return expression


	if _tokens.has_next([Lexer.TOKEN_EOF]):
		return  expression


	if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		if token == null:
			return ConditionalContentNode(expression, _line_with_action())
		return ActionContentNode(expression, _line_with_action())


	_tokens.consume([Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT])

	if token == null:
		return ConditionalContentNode(expression, _line())
	return ActionContentNode(expression, _line())


func _logic_element():
	if _tokens.has_next([Lexer.TOKEN_KEYWORD_SET]):
		var assignments = _assignments()
		return assignments


	if _tokens.has_next([Lexer.TOKEN_KEYWORD_TRIGGER]):
		var events = _events()
		return events

	if _tokens.has_next([Lexer.TOKEN_KEYWORD_WHEN]):
		_tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])

	var condition = _condition()
	return condition


func _logic_block():
	if _tokens.has_next([Lexer.TOKEN_KEYWORD_SET]):
		var assignments = _assignments()
		return ActionContentNode(assignments)

	if _tokens.has_next([Lexer.TOKEN_KEYWORD_TRIGGER]):
		var events = _events()
		return ActionContentNode(events)

	if _tokens.has_next([Lexer.TOKEN_KEYWORD_WHEN]):
		_tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])

	var condition = _condition()
	return ConditionalContentNode(condition)


func _assignments():
	_tokens.consume([Lexer.TOKEN_KEYWORD_SET])
	var assignments = [_assignment_expression()]
	while _tokens.has_next([Lexer.TOKEN_COMMA]):
		_tokens.consume([Lexer.TOKEN_COMMA])
		assignments.push_back(_assignment_expression())

	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
	return AssignmentsNode(assignments)


func _events():
	_tokens.consume([Lexer.TOKEN_KEYWORD_TRIGGER])
	_tokens.consume([Lexer.TOKEN_IDENTIFIER])
	var events = [_event(_tokens.current_token.value)]

	while _tokens.has_next([Lexer.TOKEN_COMMA]):
		_tokens.consume([Lexer.TOKEN_COMMA])
		_tokens.consume([Lexer.TOKEN_IDENTIFIER])
		events.push_back(_event(_tokens.current_token.value))

	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])

	return EventsNode(events)


func _event(event_name: String):
	if not _tokens.has_next([Lexer.TOKEN_BRACKET_OPEN]):
		return EventNode(event_name)

	_tokens.consume([Lexer.TOKEN_BRACKET_OPEN])

	var params = [_expression()]
	while _tokens.has_next([Lexer.TOKEN_COMMA]):
		_tokens.consume([Lexer.TOKEN_COMMA])
		params.push_back(_expression())

	_tokens.consume([Lexer.TOKEN_BRACKET_CLOSE])

	return EventNode(event_name, params)


func _conditional_line():
	var expression = _condition()
	var content

	if _tokens.has_next([Lexer.TOKEN_DIVERT, Lexer.TOKEN_DIVERT_PARENT]):
		content = _divert()
	elif _tokens.has_next([Lexer.TOKEN_LINE_BREAK]):
		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
		_tokens.consume([Lexer.TOKEN_INDENT])
		content = ContentNode(_lines())
		_tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])
	elif _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		content = _line_with_action()
	else:
		_tokens.consume([Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT])
		content = _line()
		if _tokens.has_next([Lexer.TOKEN_BRACE_OPEN]):
			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
			content = _line_with_action(content)

	return ConditionalContentNode(
		expression,
		content
	)


func _condition():
	var token = _tokens.peek([
		Lexer.TOKEN_IDENTIFIER,
		Lexer.TOKEN_NOT,
	])
	var expression
	if token != null:
		expression = _expression()

	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
	return expression


func _assignment_expression():
	var assignment = _assignment_expression_internal()

	if assignment.type == "variable":
		return AssignmentNode(assignment, _assignment_operators[Lexer.TOKEN_ASSIGN], BooleanLiteralNode('true'))
	else:
		return assignment


func _assignment_expression_internal():
	_tokens.consume([Lexer.TOKEN_IDENTIFIER])
	var variable = VariableNode(_tokens.current_token.value)

	if _tokens.has_next([Lexer.TOKEN_BRACE_CLOSE]):
		return variable

	var operators = _assignment_operators.keys()

	_tokens.consume(operators)

	if _tokens.has_next([Lexer.TOKEN_IDENTIFIER]) && _tokens.has_next(operators + [Lexer.TOKEN_BRACE_CLOSE], 1):
		return AssignmentNode(variable, _assignment_operators[_tokens.current_token.token], _assignment_expression_internal())
	return AssignmentNode(variable, _assignment_operators[_tokens.current_token.token], _expression())


func _expression(min_precedence = 1):
	var operator_tokens = operators.keys()

	var lhs = _operand()

	if !_tokens.has_next(operator_tokens):
		return lhs

	_tokens.consume(operator_tokens)

	while true:
		if !operator_tokens.has(_tokens.current_token.token):
			break

		var operator = _tokens.current_token.token

		var precedence = operators[_tokens.current_token.token].precedence
		var associative = operators[_tokens.current_token.token].associative

		if precedence < min_precedence:
			break

		var next_min_precedence = precedence + 1 if associative == 'LEFT' else precedence
		var rhs = _expression(next_min_precedence)
		lhs = _operator(operator, lhs, rhs)

	return lhs


func _operand():
	if _tokens.has_next([Lexer.TOKEN_NOT]):
		_tokens.consume([Lexer.TOKEN_NOT])
		return ExpressionNode('not', [_operand()])

	return _value()


func _value():
	_tokens.consume([
		Lexer.TOKEN_IDENTIFIER,
		Lexer.TOKEN_NUMBER_LITERAL,
		Lexer.TOKEN_STRING_LITERAL,
		Lexer.TOKEN_BOOLEAN_LITERAL,
		Lexer.TOKEN_NULL_TOKEN
	])

	match _tokens.current_token.token:
		Lexer.TOKEN_IDENTIFIER:
			return VariableNode(_tokens.current_token.value)
		Lexer.TOKEN_NUMBER_LITERAL:
			return NumberLiteralNode(_tokens.current_token.value)
		Lexer.TOKEN_STRING_LITERAL:
			return StringLiteralNode(_tokens.current_token.value)
		Lexer.TOKEN_BOOLEAN_LITERAL:
			return BooleanLiteralNode(_tokens.current_token.value)
		Lexer.TOKEN_NULL_TOKEN:
			return NullTokenNode()


const operator_labels = {
	Lexer.TOKEN_PLUS: 'add',
	Lexer.TOKEN_MINUS: 'sub',
	Lexer.TOKEN_MULT: 'mult',
	Lexer.TOKEN_DIV: 'div',
	Lexer.TOKEN_MOD: 'mod',
	Lexer.TOKEN_POWER: 'pow',
	Lexer.TOKEN_AND: 'and',
	Lexer.TOKEN_OR: 'or',
	Lexer.TOKEN_EQUAL: 'equal',
	Lexer.TOKEN_NOT_EQUAL: 'not_equal',
	Lexer.TOKEN_GREATER: 'greater_than',
	Lexer.TOKEN_LESS: 'less_than',
	Lexer.TOKEN_GE: 'greater_or_equal',
	Lexer.TOKEN_LE: 'less_or_equal',
}

func _operator(operator, lhs, rhs):
	return ExpressionNode(operator_labels[operator], [lhs, rhs])


func _match_block():
	_tokens.consume([Lexer.TOKEN_KEYWORD_MATCH])
	var expression = _expression()

	_tokens.consume([Lexer.TOKEN_INDENT])

	var branches = _match_block_branches()

	var default_branch

	if _tokens.has_next([Lexer.TOKEN_KEYWORD_DEFAULT]):
		_tokens.consume([Lexer.TOKEN_KEYWORD_DEFAULT])
		default_branch = _match_block_branch_content()

	_tokens.consume([Lexer.TOKEN_DEDENT])
	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])

	return MatchBlockNode(expression, branches, default_branch)


func _match_block_branches():
	var branches = []

	while _tokens.has_next([
		Lexer.TOKEN_IDENTIFIER,
		Lexer.TOKEN_NUMBER_LITERAL,
		Lexer.TOKEN_STRING_LITERAL,
		Lexer.TOKEN_BOOLEAN_LITERAL,
		Lexer.TOKEN_NULL_TOKEN
	]):
		branches.push_back(_match_block_branch())

	return branches;


func _match_block_branch():
	return {
		"check": _value(),
		"content": _match_block_branch_content(),
	}


func _match_block_branch_content():
	var hasIndent = _tokens.has_next([Lexer.TOKEN_INDENT])

	if hasIndent:
		_tokens.consume([Lexer.TOKEN_INDENT])

	var content = ContentNode(_lines())

	if hasIndent:
		_tokens.consume([Lexer.TOKEN_DEDENT])

	return content


## NODES

func DocumentNode(content = [], blocks = [], links = {}):
	return { "type": 'document', "content": content, "blocks": blocks, "links": links }


func ContentNode(content):
	return { "type": 'content',"content": content }


func BlockNode(blockName, content, meta = null):
	return _with_optional_meta({ "type": 'block', "name": blockName, "content": content }, meta)


func LineNode(value, speaker = null, id = null, tags = [], id_suffixes = null):
	return { "type": 'line', "value": value, "id": id, "speaker": speaker, "tags": tags, "id_suffixes": id_suffixes }


func OptionsNode(content, name = null, id = null, speaker = null, tags = [], id_suffixes = null, meta = null):
	return _with_optional_meta({ "type": 'options', "name": name, "content": content,"id": id, "speaker": speaker, "tags": tags, "id_suffixes": id_suffixes }, meta)


func OptionNode(content, mode, name, id, speaker, tags, id_suffixes = null):
	return { "type": 'option', "name": name, "mode": mode, "content": content, "id": id, "speaker": speaker, "tags": tags, "id_suffixes": id_suffixes }


func DivertNode(target):
	if target is String and target == 'END':
		target = '<end>'

	return { "type": 'divert', "target": target }


func VariationsNode(mode, content = []):
	return { "type": 'variations', "mode": mode,"content": content }


func VariableNode(name):
	return { "type": 'variable', "name": name }


func NumberLiteralNode(value):
	return LiteralNode('number', float(value) if value.is_valid_float() else int(value))


func BooleanLiteralNode(value):
	return LiteralNode('boolean', value == 'true')


func StringLiteralNode(value):
	return LiteralNode('string', value)


func LiteralNode(name, value):
	return { "type": 'literal', "name": name, "value": value }


func NullTokenNode():
	return { "type": 'null' }


func ConditionalContentNode(conditions, content = null):
	return { "type": 'conditional_content', "conditions": conditions, "content": content }


func ActionContentNode(action, content = null):
	return { "type": 'action_content', "action": action, "content": content }


func ExpressionNode(name, elements):
	return { "type": 'expression', "name": name, "elements": elements }


func AssignmentsNode(assignments):
	return { "type": 'assignments', "assignments": assignments }


func AssignmentNode(variable, operation, value):
	return { "type": 'assignment', "variable": variable, "operation": operation, "value": value }


func EventsNode(events):
	return { "type": 'events', "events": events }


func EventNode(name, parameters = null):
	if parameters == null or parameters.size() == 0:
		return { "type": 'event', "name": name }
	return { "type": 'event', "name": name, "params": parameters }


func MatchBlockNode(condition, branches, defeault_branch):
	return {
		"type": "match",
		"condition": condition,
		"branches": branches,
		"default_branch":  defeault_branch,
	}


func MatchBlockBranch(check, content):
	return {
		"check": check,
		"content": content,
	}


func _on_unexpected_token(result: Dictionary):
	parsing_failure.emit(result)


func _with_optional_meta(node: Dictionary, meta):
	if meta and _include_meta:
		node["meta"] = meta
	return node


func _meta(token: Dictionary):
	return {
		"column": token.column,
		"line": token.line,
	}
