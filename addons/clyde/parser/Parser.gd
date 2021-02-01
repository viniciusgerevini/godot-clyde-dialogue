extends Node

const Lexer = preload("./Lexer.gd")
const TokenWalker = preload("./TokenWalker.gd")

var _is_multiline_enabled = true

#import { TOKENS, tokenize, getTokenFriendlyHint } from './lexer.js'
#
#
#const variationsModes = ['sequence', 'once', 'cycle', 'shuffle', 'shuffle sequence', 'shuffle once', 'shuffle cycle' ]
#const operators = {
#  Lexer.TOKEN_AND: { precedence: 1, associative: 'LEFT' },
#  Lexer.TOKEN_OR: { precedence: 1, associative: 'LEFT' },
#  Lexer.TOKEN_EQUAL: { precedence: 2, associative: 'LEFT' },
#  Lexer.TOKEN_NOT_EQUAL: { precedence: 2, associative: 'LEFT' },
#  Lexer.TOKEN_GREATER: { precedence: 2, associative: 'LEFT' },
#  Lexer.TOKEN_LESS: { precedence: 2, associative: 'LEFT' },
#  Lexer.TOKEN_GE: { precedence: 2, associative: 'LEFT' },
#  Lexer.TOKEN_LE: { precedence: 2, associative: 'LEFT' },
#  Lexer.TOKEN_PLUS: { precedence: 3, associative: 'LEFT' },
#  Lexer.TOKEN_MINUS: { precedence: 3, associative: 'LEFT' },
#  Lexer.TOKEN_MOD: { precedence: 4, associative: 'LEFT' },
#  Lexer.TOKEN_MULT: { precedence: 5, associative: 'LEFT' },
#  Lexer.TOKEN_DIV: { precedence: 5, associative: 'LEFT' },
#  Lexer.TOKEN_POWER: { precedence: 7, associative: 'RIGHT' },
#}
#
#var assignmentOperators = {
#  Lexer.TOKEN_ASSIGN: 'assign',
#  Lexer.TOKEN_ASSIGN_SUM: 'assign_sum',
#  Lexer.TOKEN_ASSIGN_SUB: 'assign_sub',
#  Lexer.TOKEN_ASSIGN_MULT: 'assign_mult',
#  Lexer.TOKEN_ASSIGN_DIV: 'assign_div',
#  Lexer.TOKEN_ASSIGN_POW: 'assign_pow',
#  Lexer.TOKEN_ASSIGN_MOD: 'assign_mod',
#}

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
#			if _tokens.peek(Lexer.TOKEN_BRACE_OPEN):
#				_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#				lines = [_line_with_action(line)]
#			else:
		lines = [line]
	elif tk.token == Lexer.TOKEN_OPTION or tk.token == Lexer.TOKEN_STICKY_OPTION:
		lines = [_options()]
	elif tk.token == Lexer.TOKEN_DIVERT or tk.token == Lexer.TOKEN_DIVERT_PARENT:
		lines = [_divert()]
#			break
#		Lexer.TOKEN_BRACKET_OPEN:
#			_tokens.consume([ Lexer.TOKEN_BRACKET_OPEN ])
#			lines = [Variations()]
#			break
#		Lexer.TOKEN_LINE_BREAK:
#			_tokens.consume([ Lexer.TOKEN_LINE_BREAK ])
#		Lexer.TOKEN_BRACE_OPEN:
#			_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#			if _tokens.peek([Lexer.TOKEN_KEYWORD_SET, Lexer.TOKEN_KEYWORD_TRIGGER]):
#				lines = [_line_with_action()]
#			else:
#				lines = [ConditionalLine()]
#			}
#			break


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

		if _tokens.peek([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION]):
			pass
#			var options = _options()
#			options.id = line.id
#			options.name = line.value
#			options.tags = line.tags
#			line = options
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

	while _tokens.peek([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION]):
		options.content.push_back(_option())

	if _tokens.peek([ Lexer.TOKEN_DEDENT ]):
		_tokens.consume([ Lexer.TOKEN_DEDENT ])

	return options


func _option():
	_tokens.consume([Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION])
	var type = 'once' if _tokens.current_token.token == Lexer.TOKEN_OPTION else 'sticky'
	var acceptable_next = [Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT, Lexer.TOKEN_INDENT, Lexer.TOKEN_SQR_BRACKET_OPEN, Lexer.TOKEN_BRACE_OPEN]
	var lines = []
	var main_item
	var use_first_line_as_display_only = false
	var wrapper

	_tokens.consume(acceptable_next)

#	if _tokens.current_token.token == Lexer.TOKEN_BRACE_OPEN:
#		wrapper = LogicBlock(():})
#		_tokens.consume(acceptable_next)
#	}

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

#	if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
#		_tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#		if wrapper:
#			wrapper.content = LogicBlock(():})
#		else:
#			wrapper = LogicBlock(():})
#		}
#		_tokens.consume([Lexer.TOKEN_LINE_BREAK])
#	}

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

	if wrapper:
		if wrapper.content:
			wrapper.content.content = node
		else:
			wrapper.content = node
		return wrapper

	return node


func _divert():
	_tokens.consume([ Lexer.TOKEN_DIVERT, Lexer.TOKEN_DIVERT_PARENT ])
	var divert = _tokens.current_token

	match divert.token:
		Lexer.TOKEN_DIVERT:
			return DivertNode(divert.value)
		Lexer.TOKEN_DIVERT_PARENT:
			return DivertNode('<parent>')

#
#  var Variations():
#    var variations = VariationsNode('sequence')
#
#    if _tokens.peek([Lexer.TOKEN_VARIATIONS_MODE]):
#      var mode = _tokens.consume([Lexer.TOKEN_VARIATIONS_MODE])
#      if !variationsModes.has(mode.value):
#        throw new Error(`Wrong variation mode set "${mode.value}". Valid modes: ${variationsModes.join(', ')}.`)
#      }
#      variations.mode = mode.value
#    }
#
#    while _tokens.peek([Lexer.TOKEN_INDENT, Lexer.TOKEN_MINUS]):
#      if _tokens.peek([Lexer.TOKEN_INDENT]):
#        _tokens.consume([Lexer.TOKEN_INDENT])
#        continue
#      }
#      _tokens.consume([Lexer.TOKEN_MINUS])
#
#      var startsNextLine = false
#      if _tokens.peek([Lexer.TOKEN_INDENT]):
#        _tokens.consume([Lexer.TOKEN_INDENT])
#        startsNextLine = true
#      }
#
#      variations.content.push_back(ContentNode(_lines()))
#      if startsNextLine:
#        var lastVariation = variations.content[variations.content.size() - 1].content
#        var lastContent = lastVariation[lastVariation.size() - 1]
#        if lastContent.type != 'options':
#          _tokens.consume([Lexer.TOKEN_DEDENT])
#        }
#      }
#
#      if _tokens.peek([Lexer.TOKEN_DEDENT]):
#        _tokens.consume([Lexer.TOKEN_DEDENT])
#      }
#    }
#    _tokens.consume([Lexer.TOKEN_BRACKET_CLOSE])
#
#    return variations
#  }
#
#  var _line_with_action(line):
#    var token = _tokens.peek([
#      Lexer.TOKEN_KEYWORD_SET,
#      Lexer.TOKEN_KEYWORD_TRIGGER,
#    ])
#    var expression = LogicElement()
#
#    if line:
#      var content = line
#
#      if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
#        _tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#        content = _line_with_action(line)
#      }
#
#      if _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
#        _tokens.consume([Lexer.TOKEN_LINE_BREAK])
#      }
#
#      if !token || token.token == Lexer.TOKEN_KEYWORD_WHEN:
#        return ConditionalContentNode(expression, content)
#      }
#      return ActionContentNode(expression, content)
#    }
#
#    if _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
#      _tokens.consume([Lexer.TOKEN_LINE_BREAK])
#      return expression
#    }
#
#    if _tokens.peek([Lexer.TOKEN_EOF]):
#      return  expression
#    }
#
#    if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
#      _tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#      if !token:
#        return ConditionalContentNode(expression, _line_with_action())
#      }
#      return ActionContentNode(expression, _line_with_action())
#    }
#
#    _tokens.consume([Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT])
#
#    if !token:
#      return ConditionalContentNode(expression, _line())
#    }
#    return ActionContentNode(expression, _line())
#  }
#
#  var LogicElement():
#    if _tokens.peek([Lexer.TOKEN_KEYWORD_SET]):
#      var assignments = Assignments()
#      return assignments
#    }
#
#    if _tokens.peek([Lexer.TOKEN_KEYWORD_TRIGGER]):
#      var events = Events()
#      return events
#
#    }
#
#    if _tokens.peek([Lexer.TOKEN_KEYWORD_WHEN]):
#      _tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])
#    }
#
#    var condition = Condition()
#    return condition
#  }
#
#  var LogicBlock(content):
#    if _tokens.peek([Lexer.TOKEN_KEYWORD_SET]):
#      var assignments = Assignments()
#      return ActionContentNode(assignments, content())
#    }
#
#    if _tokens.peek([Lexer.TOKEN_KEYWORD_TRIGGER]):
#      var events = Events()
#      return ActionContentNode(events, content())
#
#    }
#
#    if _tokens.peek([Lexer.TOKEN_KEYWORD_WHEN]):
#      _tokens.consume([Lexer.TOKEN_KEYWORD_WHEN])
#    }
#
#    var condition = Condition()
#    return ConditionalContentNode(condition, content())
#  }
#
#
#  var Assignments():
#    _tokens.consume([Lexer.TOKEN_KEYWORD_SET])
#    var assignments = [AssignmentExpression()]
#    while _tokens.peek([Lexer.TOKEN_COMMA]):
#      _tokens.consume([Lexer.TOKEN_COMMA])
#      assignments.push_back(AssignmentExpression())
#    }
#    _tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
#    return AssignmentsNode(assignments)
#  }
#
#  var Events():
#    _tokens.consume([Lexer.TOKEN_KEYWORD_TRIGGER])
#    _tokens.consume([Lexer.TOKEN_IDENTIFIER])
#    var events = [EventNode(_tokens.current_token.value)]
#
#    while _tokens.peek([Lexer.TOKEN_COMMA]):
#      _tokens.consume([Lexer.TOKEN_COMMA])
#      _tokens.consume([Lexer.TOKEN_IDENTIFIER])
#      events.push_back(EventNode(_tokens.current_token.value))
#    }
#
#    _tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
#
#    return EventsNode(events)
#  }
#
#  var ConditionalLine():
#    var expression = Condition()
#
#    var content
#
#    if _tokens.peek([Lexer.TOKEN_DIVERT, Lexer.TOKEN_DIVERT_PARENT]):
#      content = _divert()
#    elif _tokens.peek([Lexer.TOKEN_LINE_BREAK]):
#      _tokens.consume([Lexer.TOKEN_LINE_BREAK])
#      _tokens.consume([Lexer.TOKEN_INDENT])
#      content = ContentNode(_lines())
#      _tokens.consume([Lexer.TOKEN_DEDENT, Lexer.TOKEN_EOF])
#    elif _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
#      _tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#      content = _line_with_action()
#    else:
#      _tokens.consume([Lexer.TOKEN_SPEAKER, Lexer.TOKEN_TEXT])
#      content = _line()
#      if _tokens.peek([Lexer.TOKEN_BRACE_OPEN]):
#        _tokens.consume([Lexer.TOKEN_BRACE_OPEN])
#        content = _line_with_action(content)
#      }
#    }
#
#    return ConditionalContentNode(
#      expression,
#      content
#    )
#  }
#
#  var Condition():
#    var token = _tokens.peek([
#      Lexer.TOKEN_IDENTIFIER,
#      Lexer.TOKEN_NOT,
#    ])
#    var expression
#    if token:
#      expression = Expression()
#    }
#    _tokens.consume([Lexer.TOKEN_BRACE_CLOSE])
#    return expression
#  }
#
#  var AssignmentExpression():
#    _tokens.consume([Lexer.TOKEN_IDENTIFIER])
#    var variable = VariableNode(_tokens.current_token.value)
#
#    if _tokens.peek([Lexer.TOKEN_BRACE_CLOSE]):
#      return variable
#    }
#
#    var operators = Object.keys(assignmentOperators)
#
#    _tokens.consume(operators)
#
#    if _tokens.peek([Lexer.TOKEN_IDENTIFIER]) && _tokens.peek([...operators, Lexer.TOKEN_BRACE_CLOSE], 1):
#      return AssignmentNode(variable, assignmentOperators[_tokens.current_token.token], AssignmentExpression())
#    }
#    return AssignmentNode(variable, assignmentOperators[_tokens.current_token.token], Expression())
#  }
#
#  var Expression(minPrecedence = 1):
#    var operatorTokens = Object.keys(operators)
#
#    var lhs = Operand()
#
#    if !_tokens.peek(operatorTokens):
#      return lhs
#    }
#
#    _tokens.consume(operatorTokens)
#
#    while true:
#      if !operatorTokens.has(_tokens.current_token.token):
#        break
#      }
#
#      var operator = _tokens.current_token.token
#
#      var { precedence, associative } = operators[_tokens.current_token.token]
#
#      if precedence < minPrecedence:
#        break
#      }
#
#      var nextMinPrecedence = associative == 'LEFT' ? precedence + 1 : precedence
#      var rhs = Expression(nextMinPrecedence)
#      lhs = Operator(operator, lhs, rhs)
#    }
#    return lhs
#  }
#
#  var Operand():
#    _tokens.consume([
#      Lexer.TOKEN_IDENTIFIER,
#      Lexer.TOKEN_NOT,
#      Lexer.TOKEN_NUMBER_LITERAL,
#      Lexer.TOKEN_STRING_LITERAL,
#      Lexer.TOKEN_BOOLEAN_LITERAL,
#      Lexer.TOKEN_NULL_TOKEN
#    ])
#
#    match _tokens.current_token.token:
#      Lexer.TOKEN_NOT:
#        return ExpressionNode('not', [Operand()])
#      Lexer.TOKEN_IDENTIFIER:
#        return VariableNode(_tokens.current_token.value)
#      Lexer.TOKEN_NUMBER_LITERAL:
#        return NumberLiteralNode(_tokens.current_token.value)
#      Lexer.TOKEN_STRING_LITERAL:
#        return StringLiteralNode(_tokens.current_token.value)
#      Lexer.TOKEN_BOOLEAN_LITERAL:
#        return BooleanLiteralNode(_tokens.current_token.value)
#      Lexer.TOKEN_NULL_TOKEN:
#        return NullTokenNode()
#    }
#  }
#
#  var Operator(operator, lhs, rhs):
#    var labels = {
#      Lexer.TOKEN_PLUS: 'add',
#      Lexer.TOKEN_MINUS: 'sub',
#      Lexer.TOKEN_MULT: 'mult',
#      Lexer.TOKEN_DIV: 'div',
#      Lexer.TOKEN_MOD: 'mod',
#      Lexer.TOKEN_POWER: 'pow',
#      Lexer.TOKEN_AND: 'and',
#      Lexer.TOKEN_OR: 'or',
#      Lexer.TOKEN_EQUAL: 'equal',
#      Lexer.TOKEN_NOT_EQUAL: 'not_equal',
#      Lexer.TOKEN_GREATER: 'greater_than',
#      Lexer.TOKEN_LESS: 'less_than',
#      Lexer.TOKEN_GE: 'greater_or_equal',
#      Lexer.TOKEN_LE: 'less_or_equal',
#    }
#    return ExpressionNode(labels[operator], [lhs, rhs])
#  }

#}

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


func ConditionalContentNode(conditions, content):
	return { "type": 'conditional_content', "conditions": conditions, "content": content }


func ActionContentNode(action, content):
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
