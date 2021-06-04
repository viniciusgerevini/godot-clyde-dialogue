extends Reference

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
}

var _tokens

func parse(doc):
	var lexer = Lexer.new()
	_tokens = TokenWalker.new()
	_tokens.set_tokens(lexer.init(doc))

#	var l = Lexer.new()
#	print(l.init(doc).get_all())

	var result = _document()
	if _tokens.peek():
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
		Lexer.TOKEN_BLOCK
	]
	var next = _tokens.peek(expected)

	if next == null:
		_tokens._wrong_token_error(next, expected)
		return

	if next.token == Lexer.TOKEN_EOF:
		return DocumentNode()


	if next.token == Lexer.TOKEN_BLOCK:
		return DocumentNode([], _blocks())

	var result =  DocumentNode([ContentNode(_lines())])

	if _tokens.peek([Lexer.TOKEN_BLOCK]):
		result.blocks = _blocks()

	return result


func _blocks():
	_tokens.consume([Lexer.TOKEN_BLOCK])
	var blocks =  [
		BlockNode(_tokens.current_token.value, ContentNode(_lines()))
	]

	while _tokens.peek([Lexer.TOKEN_BLOCK]):
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

	if !tk:
		return []

	if tk.token == Lexer.TOKEN_SPEAKER or tk.token == Lexer.TOKEN_TEXT:
		_tokens.consume([ Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT ])
		var line = _line()
		if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
			lines = [_line_with_action(line)]
		else:
			lines = [line]
	elif tk.token == Lexer.TOKEN_OPTION or tk.token == Lexer.TOKEN_STICKY_OPTION or tk.token == Lexer.TOKEN_FALLBACK_OPTION:
		lines = [_options()]
	elif tk.token == Lexer.TOKEN_DIVERT or tk.token == Lexer.TOKEN_DIVERT_PARENT:
		lines = [_divert()]
#			break
	elif tk.token == Lexer.TOKEN_BRACKET_OPEN:
			_tokens.consume([ Lexer.TOKEN_BRACKET_OPEN ])
			lines = [_variations()]
	elif tk.token == Lexer.TOKEN_LINE_BREAK or tk.token == Lexer.TOKEN_BRACE_OPEN:
		if tk.token == Lexer.TOKEN_LINE_BREAK:
			_tokens.consume([ Lexer.TOKEN_LINE_BREAK ])

		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		if _tokens.peek([Lexer.TOKEN_KEYWORD_SET, Lexer.TOKEN_KEYWORD_TRIGGER]):
			lines = [_line_with_action()]
		else:
			if _tokens.peek([Lexer.TOKEN_KEYWORD_WHEN]):
				_tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])
			lines = [_conditional_line()]


	if _tokens.peek(acceptable_next):
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

func _line_with_speaker():
	var value = _tokens.current_token.value
	_tokens.consume([Lexer.TOKEN_TEXT])
	var line = _dialogue_line()
	line.speaker =  value
	return line


func _text_line():
	var value = _tokens.current_token.value
	var next = _tokens.peek([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
	var line

	if next:
		_tokens.consume([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
		line = _line_with_metadata()
		line.value = value
	else:
		line = LineNode(value)


	if _is_multiline_enabled && _tokens.peek([Lexer.TOKEN_INDENT]):
		_tokens.consume([Lexer.TOKEN_INDENT])

		if _tokens.peek([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION, Lexer.TOKEN_FALLBACK_OPTION]):
			var options = _options()
			options.id = line.id
			options.name = line.value
			options.tags = line.tags
			line = options
		else:
			while !_tokens.peek([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF]):
				_tokens.consume([Lexer.TOKEN_TEXT])
				var nextLine = _text_line()
				line.value += " %s" % nextLine.value
				if nextLine.id:
					line.id = nextLine.id

				if nextLine.tags:
					line.tags = nextLine.tags

			_tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])

	return line

func _line_with_metadata():
	match _tokens.current_token.token:
		Lexer.TOKEN_LINE_ID:
			return _line_with_id()
		Lexer.TOKEN_TAG:
			return _line_with_tags()


func _line_with_id():
	var value = _tokens.current_token.value
	var next = _tokens.peek([Lexer.TOKEN_TAG])
	if next:
		_tokens.consume([Lexer.TOKEN_TAG])
		var line = _line_with_tags()
		line.id = value
		return line

	return LineNode(null, null, value)


func _line_with_tags():
	var value = _tokens.current_token.value
	var next = _tokens.peek([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
	if next:
		_tokens.consume([Lexer.TOKEN_LINE_ID, Lexer.TOKEN_TAG])
		var line = _line_with_metadata()
		if not line.tags:
			line.tags = []

		line.tags.push_front(value)
		return line

	return LineNode(null, null, null, [value])


func _options():
	var options = OptionsNode([])

	while _tokens.peek([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION, Lexer.TOKEN_FALLBACK_OPTION]):
		options.content.push_back(_option())

	if _tokens.peek([ Lexer.TOKEN_DEDENT ]):
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
	var acceptable_next = [Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT, Lexer.TOKEN_INDENT, Lexer.TOKEN_SQR_BRACKET_OPEN, Lexer.TOKEN_BRACE_OPEN]
	var lines = []
	var main_item
	var use_first_line_as_display_only = false
	var root
	var wrapper

	_tokens.consume(acceptable_next)

	if _tokens.current_token.token == Lexer.TOKEN_BRACE_OPEN:
		var block = _nested_logic_block()
		root = block.root
		wrapper = block.wrapper
		_tokens.consume(acceptable_next)


	if _tokens.current_token.token == Lexer.TOKEN_SQR_BRACKET_OPEN:
		use_first_line_as_display_only = true
		_tokens.consume(acceptable_next)

	if _tokens.current_token.token == Lexer.TOKEN_SPEAKER or _tokens.current_token.token == Lexer.TOKEN_TEXT:
			_is_multiline_enabled = false
			main_item = _line()
			_is_multiline_enabled = true
			if use_first_line_as_display_only:
				_tokens.consume([Lexer.TOKEN_SQR_BRACKET_CLOSE])
			else:
				lines.push_back(main_item)


	if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		var block = _nested_logic_block()

		if not root:
			root = block.root
			wrapper = block.wrapper
		else:
			wrapper.content = block.wrapper
			wrapper = block.wrapper

		_tokens.consume([Lexer.TOKEN_LINE_BREAK])


	if _tokens.current_token.token == Lexer.TOKEN_INDENT || _tokens.peek([Lexer.TOKEN_INDENT]):
		if _tokens.current_token.token != Lexer.TOKEN_INDENT:
			_tokens.consume([Lexer.TOKEN_INDENT])

		lines = lines + _lines()
		if !main_item:
			main_item = lines[0]

		_tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])


	var node = OptionNode(
		ContentNode(lines),
		type,
		main_item.value,
		main_item.id,
		main_item.speaker,
		main_item.tags
	)

	if root:
		wrapper.content = node
		return root

	return node


func _nested_logic_block():
	var root
	var wrapper
	while _tokens.current_token.token == Lexer.TOKEN_BRACE_OPEN:
		if not root:
			root = _logic_block()
			wrapper = root
		else:
			var next = _logic_block()
			wrapper.content = next
			wrapper = next

		if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
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

	if _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
		return token

	if _tokens.peek([Lexer.TOKEN_EOF]):
		return  token

	if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		token = _line_with_action(token)


	return token


func _variations():
	var variations = VariationsNode('sequence')

	if _tokens.peek([Lexer.TOKEN_VARIATIONS_MODE]):
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

	while _tokens.peek([Lexer.TOKEN_INDENT, Lexer.TOKEN_MINUS]):
		if _tokens.peek([Lexer.TOKEN_INDENT]):
			_tokens.consume([Lexer.TOKEN_INDENT])
			continue

		_tokens.consume([Lexer.TOKEN_MINUS])

		var starts_next_line = false
		if _tokens.peek([Lexer.TOKEN_INDENT]):
			_tokens.consume([Lexer.TOKEN_INDENT])
			starts_next_line = true


		variations.content.push_back(ContentNode(_lines()))
		if starts_next_line:
			var lastVariation = variations.content[variations.content.size() - 1].content
			var lastContent = lastVariation[lastVariation.size() - 1]
			if lastContent.type != 'options':
				_tokens.consume([Lexer.TOKEN_DEDENT])

		if _tokens.peek([Lexer.TOKEN_DEDENT]):
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

		if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
			content = _line_with_action(line)


		if _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
			_tokens.consume([Lexer.TOKEN_LINE_BREAK])


		if !token || token.token == Lexer.TOKEN_KEYWORD_WHEN:
			return ConditionalContentNode(expression, content)

		return ActionContentNode(expression, content)


	if _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
		return expression


	if _tokens.peek([Lexer.TOKEN_EOF]):
		return  expression


	if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		if !token:
			return ConditionalContentNode(expression, _line_with_action())
		return ActionContentNode(expression, _line_with_action())


	_tokens.consume([Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT])

	if !token:
		return ConditionalContentNode(expression, _line())
	return ActionContentNode(expression, _line())


func _logic_element():
	if _tokens.peek([Lexer.TOKEN_KEYWORD_SET]):
		var assignments = _assignments()
		return assignments


	if _tokens.peek([Lexer.TOKEN_KEYWORD_TRIGGER]):
		var events = _events()
		return events

	if _tokens.peek([Lexer.TOKEN_KEYWORD_WHEN]):
		_tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])

	var condition = _condition()
	return condition


func _logic_block():
	if _tokens.peek([Lexer.TOKEN_KEYWORD_SET]):
		var assignments = _assignments()
		return ActionContentNode(assignments)

	if _tokens.peek([Lexer.TOKEN_KEYWORD_TRIGGER]):
		var events = _events()
		return ActionContentNode(events)

	if _tokens.peek([Lexer.TOKEN_KEYWORD_WHEN]):
		_tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])

	var condition = _condition()
	return ConditionalContentNode(condition)


func _assignments():
	_tokens.consume([Lexer.TOKEN_KEYWORD_SET])
	var assignments = [_assignment_expression()]
	while _tokens.peek([Lexer.TOKEN_COMMA]):
		_tokens.consume([Lexer.TOKEN_COMMA])
		assignments.push_back(_assignment_expression())

	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
	return AssignmentsNode(assignments)


func _events():
	_tokens.consume([Lexer.TOKEN_KEYWORD_TRIGGER])
	_tokens.consume([Lexer.TOKEN_IDENTIFIER])
	var events = [EventNode(_tokens.current_token.value)]

	while _tokens.peek([Lexer.TOKEN_COMMA]):
		_tokens.consume([Lexer.TOKEN_COMMA])
		_tokens.consume([Lexer.TOKEN_IDENTIFIER])
		events.push_back(EventNode(_tokens.current_token.value))

	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])

	return EventsNode(events)


func _conditional_line():
	var expression = _condition()
	var content

	if _tokens.peek([Lexer.TOKEN_DIVERT, Lexer.TOKEN_DIVERT_PARENT]):
		content = _divert()
	elif _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
		_tokens.consume([Lexer.TOKEN_INDENT])
		content = ContentNode(_lines())
		_tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])
	elif _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
		content = _line_with_action()
	else:
		_tokens.consume([Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT])
		content = _line()
		if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
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
	if token:
		expression = _expression()

	_tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
	return expression


func _assignment_expression():
	_tokens.consume([Lexer.TOKEN_IDENTIFIER])
	var variable = VariableNode(_tokens.current_token.value)

	if _tokens.peek([Lexer.TOKEN_BRACE_CLOSE]):
		return variable

	var operators = _assignment_operators.keys()

	_tokens.consume(operators)

	if _tokens.peek([Lexer.TOKEN_IDENTIFIER]) && _tokens.peek(operators + [Lexer.TOKEN_BRACE_CLOSE], 1):
		return AssignmentNode(variable, _assignment_operators[_tokens.current_token.token], _assignment_expression())
	return AssignmentNode(variable, _assignment_operators[_tokens.current_token.token], _expression())


func _expression(min_precedence = 1):
	var operator_tokens = operators.keys()

	var lhs = _operand()

	if !_tokens.peek(operator_tokens):
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
	_tokens.consume([
		Lexer.TOKEN_IDENTIFIER,
		Lexer.TOKEN_NOT,
		Lexer.TOKEN_NUMBER_LITERAL,
		Lexer.TOKEN_STRING_LITERAL,
		Lexer.TOKEN_BOOLEAN_LITERAL,
		Lexer.TOKEN_NULL_TOKEN
	])

	match _tokens.current_token.token:
		Lexer.TOKEN_NOT:
			return ExpressionNode('not', [_operand()])
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


## NODES

func DocumentNode(content = [], blocks = []):
	return { "type": 'document', "content": content, "blocks": blocks }


func ContentNode(content):
	return { "type": 'content',"content": content }


func BlockNode(blockName, content):
	return { "type": 'block', "name": blockName, "content": content }


func LineNode(value, speaker = null, id = null, tags = null):
	return { "type": 'line', "value": value, "id": id, "speaker": speaker, "tags": tags }


func OptionsNode(content, name = null, id = null, speaker = null, tags = null):
	return { "type": 'options', "name": name, "content": content,"id": id, "speaker": speaker, "tags": tags }


func OptionNode(content, mode, name, id, speaker, tags):
	return { "type": 'option', "name": name, "mode": mode, "content": content, "id": id, "speaker": speaker, "tags": tags }


func DivertNode(target):
	if target == 'END':
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


func EventNode(name):
	return { "type": 'event', "name": name }
