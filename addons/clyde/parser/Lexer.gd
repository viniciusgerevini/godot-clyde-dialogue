extends RefCounted

const TOKEN_TEXT = "TEXT"
const TOKEN_INDENT = "INDENT"
const TOKEN_DEDENT = "DEDENT"
const TOKEN_OPTION = "OPTION"
const TOKEN_STICKY_OPTION = "STICKY_OPTION"
const TOKEN_FALLBACK_OPTION = "FALLBACK_OPTION"
const TOKEN_BRACKET_OPEN = "BRACKET_OPEN"
const TOKEN_BRACKET_CLOSE = "BRACKET_CLOSE"
const TOKEN_EOF = "EOF"
const TOKEN_SPEAKER = "SPEAKER"
const TOKEN_LINE_ID = "LINE_ID"
const TOKEN_ID_SUFFIX = "ID_SUFFIX"
const TOKEN_TAG = "TAG"
const TOKEN_BLOCK = "BLOCK"
const TOKEN_DIVERT = "DIVERT"
const TOKEN_DIVERT_PARENT = "DIVERT_PARENT"
const TOKEN_VARIATIONS_MODE = "VARIATIONS_MODE"
const TOKEN_MINUS = "-"
const TOKEN_PLUS = "+"
const TOKEN_MULT = "*"
const TOKEN_DIV = "/"
const TOKEN_POWER = "^"
const TOKEN_MOD = "%"
const TOKEN_BRACE_OPEN = "{"
const TOKEN_BRACE_CLOSE = "}"
const TOKEN_AND = "AND"
const TOKEN_OR = "OR"
const TOKEN_NOT ="NOT"
const TOKEN_EQUAL = "==, is"
const TOKEN_NOT_EQUAL = "!=, isnt"
const TOKEN_GE = ">="
const TOKEN_LE = "<="
const TOKEN_GREATER = "GREATER"
const TOKEN_LESS = "LESS"
const TOKEN_NUMBER_LITERAL = "number"
const TOKEN_NULL_TOKEN = "null"
const TOKEN_BOOLEAN_LITERAL = "boolean"
const TOKEN_STRING_LITERAL = "string"
const TOKEN_IDENTIFIER = "identifier"
const TOKEN_KEYWORD_SET = "set"
const TOKEN_KEYWORD_TRIGGER = "trigger"
const TOKEN_KEYWORD_WHEN = "when"
const TOKEN_KEYWORD_MATCH = "match"
const TOKEN_KEYWORD_DEFAULT = "default"
const TOKEN_ASSIGN = "="
const TOKEN_ASSIGN_SUM = "+="
const TOKEN_ASSIGN_SUB = "-="
const TOKEN_ASSIGN_DIV = "/="
const TOKEN_ASSIGN_MULT = "*="
const TOKEN_ASSIGN_POW = "^="
const TOKEN_ASSIGN_MOD = "%="
const TOKEN_ASSIGN_INIT = "?="
const TOKEN_COMMA = ","
const TOKEN_LINE_BREAK = "line break"
const TOKEN_LINK_FILE = "link file"

const MODE_DEFAULT = "DEFAULT"
const MODE_OPTION = "OPTION"
const MODE_QSTRING = "QSTRING"
const MODE_LOGIC = "LOGIC"
const MODE_VARIATIONS = "VARIATIONS"
const MODE_MATCH = "MATCH"
const MODE_MATCH_BODY = "MATCH_BODY"


const _token_hints = {
	TOKEN_TEXT: 'text',
	TOKEN_INDENT: 'INDENT',
	TOKEN_DEDENT: 'DEDENT',
	TOKEN_OPTION: '*',
	TOKEN_STICKY_OPTION: '+',
	TOKEN_FALLBACK_OPTION: '>',
	TOKEN_BRACKET_OPEN: '(',
	TOKEN_BRACKET_CLOSE: ')',
	TOKEN_EOF: 'EOF',
	TOKEN_SPEAKER: '<speaker name>:',
	TOKEN_LINE_ID: '$id',
	TOKEN_ID_SUFFIX: '&id_suffix',
	TOKEN_TAG: '#tag',
	TOKEN_BLOCK: '== <block name>',
	TOKEN_DIVERT: '-> <target name>',
	TOKEN_DIVERT_PARENT: '<-',
	TOKEN_VARIATIONS_MODE: '<variations mode>',
	TOKEN_BRACE_OPEN: '{',
	TOKEN_BRACE_CLOSE: '}',
	TOKEN_AND: '&&, and',
	TOKEN_OR: '||, or',
	TOKEN_NOT:' not, !',
	TOKEN_EQUAL: '==, is',
	TOKEN_NOT_EQUAL: '!=, isnt',
	TOKEN_GE: '>=',
	TOKEN_LE: '<=',
	TOKEN_GREATER: '>',
	TOKEN_LESS: '<',
	TOKEN_LINK_FILE: "@link <import> | <import_name> = <import_path>",
}

const _keywords = [
	'is', 'isnt', 'or', 'and', 'not', 'true', 'false', 'null',
	'set', 'trigger', 'when', 'match',
]

var _input = ""
var _indent = [0]
var _position = 0
var _line = 0
var _column = 0
var _length = 0
var _pending_tokens = []
var _modes = [ MODE_DEFAULT ]
var _current_quote = ""
var _match_body_indent: Array[int] = []
var _is_inline_match_branch: bool = false


static func get_token_friendly_hint(token):
	return _token_hints.get(token, token)


func init(input):
	_input = input
	_indent = [0]
	_position = 0
	_line = 0
	_column = 0
	_length = input.length()
	_pending_tokens = []

	return self

func get_all():
	var tokens = []
	while _position < _length:
		var token = _get_next_token()
		if token:
			if typeof(token) == TYPE_ARRAY:
				tokens = tokens + token
			else:
				tokens.push_back(token)

	_position += 1
	tokens.push_back(Token(TOKEN_EOF, _line, _column))

	return tokens


func next():
	if _pending_tokens.size() > 0:
		return _pending_tokens.pop_front()

	while _position < _length:
		var token = _get_next_token()
		if token != null:
			if typeof(token) == TYPE_ARRAY:
				_pending_tokens = token
				return _pending_tokens.pop_front()
			else:
				return token

	if _position == _length:
		_position += 1
		return Token(TOKEN_EOF, _line, _column)


func _stack_mode(mode):
	_modes.push_front(mode)


func _pop_mode():
	if _modes.size() > 1:
		_modes.pop_front()


func _is_current_mode(mode):
	return _modes[0] == mode


func _get_next_token():
	if not _is_current_mode(MODE_QSTRING) and _check_sequence(_input, _position, "--"):
		return _handle_comments()

	if not _is_current_mode(MODE_QSTRING) and _input[_position] == '\n':
		return _handle_line_breaks()

	if not _is_current_mode(MODE_LOGIC) and ((_column == 0 and _is_tab_char(_input[_position])) or (_column == 0 and _indent.size() > 1)):
		return _handle_indent()

	if not _is_current_mode(MODE_QSTRING) and _input[_position] == '{':
		return _handle_logic_or_match_block_start()

	if _is_current_mode(MODE_LOGIC):
		var response = _handle_logic_block()

		if response:
			return response

	if _is_current_mode(MODE_MATCH):
		var response = _handle_match_block()

		if response:
			return response


	if _input[_position] == '"' or _input[_position] == "'":
		if _current_quote:
			if _input[_position] == _current_quote:
				return _handle_quote()
		else:
			_current_quote = _input[_position]
			return _handle_quote()

	if _is_current_mode(MODE_QSTRING):
		return _handle_qtext()

	if _input[_position] == ' ':
		return _handle_space()

	if _is_tab_char(_input[_position]):
		return _handle_rogue_tab()

	if _input[_position] == '(':
		return _handle_start_variations()

	if _input[_position] == ')':
		return _handle_stop_variations()

	if _column == 0 and _check_sequence(_input, _position, "=="):
		return _handle_block()

	if _column == 0 and _check_sequence(_input, _position, "@link "):
		return _handle_link()

	if _check_sequence(_input, _position, "->"):
		return _handle_divert()

	if _check_sequence(_input, _position, "<-"):
		return _handle_divert_parent()

	if _is_current_mode(MODE_VARIATIONS) and _input[_position] == '-':
		return _handle_variation_item()

	if _input[_position] == '*' or _input[_position] == '+' or _input[_position] == '>':
		return _handle_options()

	if _is_current_mode(MODE_OPTION) and _input[_position] == '=':
		return _handle_option_display_char()

	if _input[_position] == '$':
		return _handle_line_id()

	if _input[_position] == '#':
		return _handle_tag()

	return _handle_text()


func _handle_line_breaks():
	while _is_valid_position() and _input[_position] == '\n':
		_line += 1
		_position += 1
		_column = 0

		if _is_current_mode(MODE_OPTION):
			_pop_mode()
		elif _is_current_mode(MODE_MATCH_BODY) && _is_inline_match_branch:
			_pop_mode()


func _handle_space():
	while _input[_position] == ' ':
		_position += 1
		_column += 1


func _handle_rogue_tab():
	var tab = RegEx.new()
	tab.compile("[\t]")
	while tab.search(_input[_position]) != null:
		_position += 1
		_column += 1


func _handle_indent():
	var initial_line = _line

	var indentation = 0
	while _is_valid_position() and _is_tab_char(_input[_position]):
		indentation += 1
		_position += 1

	if indentation > _indent[0]:
		var previous_indent = _indent[0]
		_column += indentation
		_indent.push_front(indentation)

		if _is_current_mode(MODE_MATCH_BODY):
			_match_body_indent.push_back(previous_indent)

		return Token(TOKEN_INDENT, initial_line, previous_indent)

	if indentation == _indent[0]:
		_column = _indent[0]
		return

	var tokens = []
	while indentation < _indent[0]:
		_indent.pop_front()
		_column = _indent[0]
		tokens.push_back(Token(TOKEN_DEDENT, _line, _column))

		if _is_match_body_indent_level(_column):
			_pop_mode()
			_match_body_indent.pop_back()

	return tokens


func _handle_comments():
	while _is_valid_position() and _input[_position] != '\n':
		_position += 1

	_position += 1
	_line += 1


func _handle_text():
	var initialLine = _line
	var initial_column = _column
	var value = []

	while _position < _input.length():
		var current_char = _input[_position]

		if ['\n', '$', '#', '{' ].has(current_char):
			break

		if current_char == "\\" and _input[_position + 1] != 'n':
			value.push_back(_input[_position + 1])
			_position += 2
			_column += 2
			continue

		if current_char == ':':
			_position += 1
			_column += 1
			return Token(TOKEN_SPEAKER, initialLine, initial_column, _array_join(value).strip_edges())

		value.push_back(current_char)

		_position += 1
		_column += 1

	return Token(TOKEN_TEXT, initialLine, initial_column, _array_join(value).strip_edges())


func _handle_line_id():
	var initial_column = _column
	var values = []
	_position += 1
	_column += 1

	while (_is_valid_position() and _is_identifier(_input[_position])):
		values.push_back(_input[_position])
		_position += 1
		_column += 1

	var id = Token(TOKEN_LINE_ID, _line, initial_column, _array_join(values))
	var tokens = [id]

	while _is_valid_position() and  _input[_position] == '&':
		tokens.push_back(_handle_id_suffix())

	return tokens


func _handle_id_suffix():
	var initial_column = _column
	var values = []
	_position += 1
	_column += 1

	while (_is_valid_position() and _is_identifier(_input[_position])):
		values.push_back(_input[_position])
		_position += 1
		_column += 1

	return Token(TOKEN_ID_SUFFIX, _line, initial_column, _array_join(values))


func _handle_tag():
	var initial_column = _column
	var values = []
	_position += 1
	_column += 1

	while _is_valid_position() and _is_tag(_input[_position]):
		values.push_back(_input[_position])
		_position += 1
		_column += 1

	return Token(TOKEN_TAG, _line, initial_column, _array_join(values))


func _handle_qtext():
	var initialLine = _line
	var initial_column = _column
	var value = []

	while _position < _input.length():
		var current_char = _input[_position]

		if current_char == _current_quote:
			break

		if current_char == '\\' and _input[_position + 1] == _current_quote:
			value.push_back(_input[_position + 1])
			_position += 2
			_column += 2
			continue

		if current_char == '\n':
			_line += 1

		value.push_back(current_char)

		_position += 1
		_column += 1

	return Token(TOKEN_TEXT, initialLine, initial_column, _array_join(value).strip_edges())


func _handle_quote():
	_column += 1
	_position += 1
	if _is_current_mode(MODE_QSTRING):
		_current_quote = ""
		_pop_mode()
	else:
		_stack_mode(MODE_QSTRING)


func _handle_options():
	var token
	match _input[_position]:
		'*':
			token = TOKEN_OPTION
		'+':
			token = TOKEN_STICKY_OPTION
		'>':
			token = TOKEN_FALLBACK_OPTION
	var initial_column = _column
	_column += 1
	_position += 1
	_stack_mode(MODE_OPTION)
	return Token(token, _line, initial_column)


func _handle_option_display_char():
	var initial_column = _column
	_column += 1
	_position += 1
	return Token(TOKEN_ASSIGN, _line, initial_column)


func _handle_link():
	var initial_column = _column
	var values = []

	# skip @link
	_position += 6
	_column += 6

	var link_string = ""

	var link_name = ""
	var link_path = ""

	while _is_valid_position() and _input[_position] != '\n':
		if _is_identifier(_input[_position]):
			link_name += _input[_position]
			_position += 1
			_column += 1
		else:
			break

	var has_assignment = false
	while _is_valid_position() and _input[_position] != '\n' and (_input[_position] == ' ' or _input[_position] == '='):
		_position += 1
		_column += 1
		if _input[_position] == '=':
			has_assignment = true

	if has_assignment:
		while _is_valid_position() and _input[_position] != '\n':
			link_path += _input[_position]
			_position += 1
			_column += 1
	elif _input[_position] == "\n":
		link_path = link_name


	return Token(TOKEN_LINK_FILE, _line, initial_column, { "name": link_name, "path": link_path })



func _handle_block():
	var initial_column = _column
	var values = []
	_position += 2
	_column += 2

	while _is_valid_position() and _is_block_identifier(_input[_position]):
		values.push_back(_input[_position])
		_position += 1
		_column += 1
	return Token(TOKEN_BLOCK, _line, initial_column, _array_join(values).strip_edges())


func _handle_divert():
	var initial_column = _column
	var values = []
	_position += 2
	_column += 2

	while _is_valid_position() and _input[_position] == " ":
		_position += 1
		_column += 1

	var token

	if _input[_position] == "@":
		_position += 1
		_column += 1
		token = _handle_divert_ext(initial_column)
	else:
		while _is_valid_position() and _is_block_identifier(_input[_position]):
			values.push_back(_input[_position])
			_position += 1
			_column += 1

		token = Token(TOKEN_DIVERT, _line, initial_column, _array_join(values).strip_edges())

	var linebreak = _get_following_line_break()
	if linebreak:
		return [ token, linebreak ]

	return token


func _handle_divert_ext(initial_column):
	var link_name = ""
	var link_block = ""

	while _is_valid_position() and _is_identifier(_input[_position]):
		link_name += _input[_position]
		_position += 1
		_column += 1

	if _is_valid_position() and _input[_position] == ".":
		_position += 1
		_column += 1

		while _is_valid_position() and _is_block_identifier(_input[_position]):
			link_block += _input[_position]
			_position += 1
			_column += 1

	return Token(TOKEN_DIVERT, _line, initial_column, { "link": link_name, "block": link_block })



func _handle_divert_parent():
	var initial_column = _column
	_position += 2
	_column += 2

	var token = Token(TOKEN_DIVERT_PARENT, _line, initial_column)

	var linebreak = _get_following_line_break()
	if linebreak:
		return [ token, linebreak ]

	return token

func _handle_start_variations():
	var initial_column = _column
	var values = []
	_column += 1
	_position += 1
	_stack_mode(MODE_VARIATIONS)

	var identifier = RegEx.new()
	identifier.compile("[A-Z|a-z| ]")

	while _is_valid_position() and identifier.search(_input[_position]) != null:
		values.push_back(_input[_position])
		_position += 1
		_column += 1

	var tokens = [
		Token(TOKEN_BRACKET_OPEN, _line, initial_column)
	]

	var value = _array_join(values).strip_edges()

	if value.length() > 0:
		tokens.push_back(Token(TOKEN_VARIATIONS_MODE, _line, initial_column + 2, value))

	return tokens


func _handle_stop_variations():
	var initial_column = _column
	_column += 1
	_position += 1
	_pop_mode()
	return Token(TOKEN_BRACKET_CLOSE, _line, initial_column)


func _handle_variation_item():
	var initial_column = _column
	_column += 1
	_position += 1
	return Token(TOKEN_MINUS, _line, initial_column)


func _handle_logic_or_match_block_start():
	var block_start = _handle_logic_block_start()

	while _is_valid_position() and _is_tab_space_or_line_break(_input[_position]):
		if _input[_position] == '\n':
			_line += 1
			_column = 0
		else:
			_column += 1

		_position += 1

	if _check_sequence(_input, _position, 'match'):
		var token = Token(TOKEN_KEYWORD_MATCH, _line, _column)
		_position += 5
		_column += 5

		_handle_space()

		var statement = _handle_logic_statement()
		_stack_mode(MODE_MATCH)


		if statement == null:
			return _merge_into_array([block_start, token])
		return _merge_into_array([block_start, token, statement])

	return block_start


func _handle_match_block():
	if _input[_position] == '}':
		_column += 1
		_position += 1
		_pop_mode() # pop match
		_pop_mode() # pop logic
		return Token(TOKEN_BRACE_CLOSE, _line, _column - 1)

	var statement

	if _check_sequence(_input, _position, 'default:'):
		statement = Token(TOKEN_KEYWORD_DEFAULT, _line, _column)
		_position += 7
		_column += 7
	else:
		statement = _handle_logic_statement()

	if _input[_position] == ':':
		_column += 1
		_position += 1
		_stack_mode(MODE_MATCH_BODY)
		_is_inline_match_branch = false
		var p = _position

		while p < _input.length() and _input[p] != '\n':
			if _input[p] != ' ':
				_is_inline_match_branch = true
				break
			p += 1

	return statement


func _handle_logic_block_start():
	var initial_column = _column
	_column += 1
	_position += 1
	_stack_mode(MODE_LOGIC)
	var token = Token(TOKEN_BRACE_OPEN, _line, initial_column)
	var linebreak = _get_leading_line_break()
	if linebreak:
		return [ linebreak, token ]

	return token


func _handle_logic_block_stop():
	var initial_column = _column
	_column += 1
	_position += 1
	_pop_mode()
	var token = Token(TOKEN_BRACE_CLOSE, _line, initial_column)
	var linebreak = _get_following_line_break()
	if linebreak:
		return [ token, linebreak ]

	return token


func _handle_logic_block():
	if _input[_position] == '}':
		return _handle_logic_block_stop()

	return _handle_logic_statement()


func _handle_logic_statement():
	if _input[_position] == '"' or _input[_position] == "'":
		if _current_quote != null:
			_current_quote = _input[_position]
		return _handle_logic_string()

	if _input[_position] == '(':
		return _create_simple_token(TOKEN_BRACKET_OPEN)

	if _input[_position] == ')':
		return _create_simple_token(TOKEN_BRACKET_CLOSE)

	if _check_sequence(_input, _position, '=='):
		return _handle_logic_operator(TOKEN_EQUAL, 2)

	if _check_sequence(_input, _position, '!='):
		return _handle_logic_operator(TOKEN_NOT_EQUAL, 2)

	if _check_sequence(_input, _position, '&&'):
		return _handle_logic_operator(TOKEN_AND, 2)

	if _check_sequence(_input, _position, '||'):
		return _handle_logic_operator(TOKEN_OR, 2)

	if _check_sequence(_input, _position, '<='):
		return _handle_logic_operator(TOKEN_LE, 2)

	if _check_sequence(_input, _position, '>='):
		return _handle_logic_operator(TOKEN_GE, 2)

	if _check_sequence(_input, _position, '<'):
		return _handle_logic_operator(TOKEN_LESS, 1)

	if _check_sequence(_input, _position, '>'):
		return _handle_logic_operator(TOKEN_GREATER, 1)

	if _input[_position] == '=':
		return _create_simple_token(TOKEN_ASSIGN)

	if _check_sequence(_input, _position, '?='):
		return _handle_logic_operator(TOKEN_ASSIGN_INIT, 2)


	if _check_sequence(_input, _position, '-='):
		return _create_simple_token(TOKEN_ASSIGN_SUB, 2)

	if _check_sequence(_input, _position, '+='):
		return _create_simple_token(TOKEN_ASSIGN_SUM, 2)

	if _check_sequence(_input, _position, '*='):
		return _create_simple_token(TOKEN_ASSIGN_MULT, 2)

	if _check_sequence(_input, _position, '/='):
		return _create_simple_token(TOKEN_ASSIGN_DIV, 2)

	if _check_sequence(_input, _position, '^='):
		return _create_simple_token(TOKEN_ASSIGN_POW, 2)

	if _check_sequence(_input, _position, '%='):
		return _create_simple_token(TOKEN_ASSIGN_MOD, 2)

	if _input[_position] == '+':
		return _create_simple_token(TOKEN_PLUS, 1)

	if _input[_position] == '-':
		return _create_simple_token(TOKEN_MINUS, 1)

	if _input[_position] == '*':
		return _create_simple_token(TOKEN_MULT, 1)

	if _input[_position] == '/':
		return _create_simple_token(TOKEN_DIV, 1)

	if _input[_position] == '^':
		return _create_simple_token(TOKEN_POWER, 1)

	if _input[_position] == '%':
		return _create_simple_token(TOKEN_MOD, 1)

	if _input[_position] == ',':
		return _create_simple_token(TOKEN_COMMA, 1)

	if _input[_position] == '!':
		return _handle_logic_not()

	if _input[_position].is_valid_int():
		return _handle_logic_number()

	var identifier_start = RegEx.create_from_string("[A-Z|a-z|@|_]")

	if identifier_start.search(_input[_position]) != null:
		return _handle_logic_identifier()


func _handle_logic_identifier():
	var initial_column = _column
	var values = ''

	# global char prefix. Only allowed as first char in identifier
	if _input[_position] == "@":
		values += "@"
		_position += 1
		_column += 1


	while _is_valid_position() and _is_identifier(_input[_position]):
		values += _input[_position]
		_position += 1
		_column += 1

	if _keywords.has(values.to_lower()):
		return _handle_logic_descpritive_operator(values, initial_column)


	return Token(TOKEN_IDENTIFIER, _line, initial_column, values.strip_edges())


func _handle_logic_descpritive_operator(value, initial_column):
	match value.to_lower():
		'not':
			return Token(TOKEN_NOT, _line, initial_column)
		'and':
			return Token(TOKEN_AND, _line, initial_column)
		'or':
			return Token(TOKEN_OR, _line, initial_column)
		'is':
			return Token(TOKEN_EQUAL, _line, initial_column)
		'isnt':
			return Token(TOKEN_NOT_EQUAL, _line, initial_column)
		'true':
			return Token(TOKEN_BOOLEAN_LITERAL, _line, initial_column, value)
		'false':
			return Token(TOKEN_BOOLEAN_LITERAL, _line, initial_column, value)
		'null':
			return Token(TOKEN_NULL_TOKEN, _line, initial_column)
		'set':
			return Token(TOKEN_KEYWORD_SET, _line, initial_column)
		'trigger':
			return Token(TOKEN_KEYWORD_TRIGGER, _line, initial_column)
		'when':
			return Token(TOKEN_KEYWORD_WHEN, _line, initial_column)


func _handle_logic_not():
	var initial_column = _column
	_column += 1
	_position += 1
	return Token(TOKEN_NOT, _line, initial_column)


func _handle_logic_operator(token, length):
	var initial_column = _column
	_column += length
	_position += length
	return Token(token, _line, initial_column)


func _handle_logic_number():
	var initial_column = _column
	var values = ''

	while _is_valid_position() and (_input[_position] == '.' or _input[_position].is_valid_int()):
		values += _input[_position]
		_position += 1
		_column += 1

	return Token(TOKEN_NUMBER_LITERAL, _line, initial_column, values)


func _handle_logic_string():
	var initial_column = _column
	_column += 1
	_position += 1
	var token = _handle_qtext()
	_column += 1
	_position += 1

	token.token = TOKEN_STRING_LITERAL
	token.column = initial_column

	return token


func _create_simple_token(token, length = 1):
	var initial_column = _column
	_column += length
	_position += length
	return Token(token, _line, initial_column)


func _get_following_line_break():
	var lookup_position = _position
	var lookup_column = _column

	while _is_valid_position() and _is_tab_char(_input[lookup_position]):
		lookup_position += 1
		lookup_column += 1

	if  _is_valid_position() and _input[lookup_position] == '\n':
		return Token(TOKEN_LINE_BREAK, _line, lookup_column)


func _get_leading_line_break():
	var lookup_position = _position - 2
	while _is_tab_char(_input[lookup_position]):
		lookup_position -= 1

	if _input[lookup_position] == '\n':
		return Token(TOKEN_LINE_BREAK, _line, 0)


static func Token(token, line, column, value = null):
	return {
		"token": token,
		"value": value,
		"line": line,
		"column": column
	}

func _array_join(arr, separator = ""):
	var output = "";
	for s in arr:
		output += str(s) + separator
	output = output.left(output.length() - separator.length())
	return output


func _is_tab_char(character):
	var tab = RegEx.new()
	tab.compile("[\t ]")
	return tab.search(character) != null


func _is_tab_space_or_line_break(character):
	var rgx = RegEx.new()
	rgx.compile("[\n\t ]")
	return rgx.search(character) != null


func _is_valid_position():
	return _position < _input.length() and _input[_position]


func _is_tag(character):
	var lineId = RegEx.create_from_string("[A-Z|a-z|0-9|_|\\-|\\.]")
	return lineId.search(character) != null


func _is_identifier(character):
	var lineId = RegEx.create_from_string("[A-Z|a-z|0-9|_]")
	return lineId.search(character) != null


func _is_block_identifier(character):
	var identifier = RegEx.create_from_string("[A-Z|a-z|0-9|_| ]")
	return identifier.search(character) != null


func _check_sequence(string, initial_position, value):
	var sequence = string.substr(initial_position, value.length())
	return sequence == value


func _is_match_body_indent_level(current_indent: int) -> bool:
	return _is_current_mode(MODE_MATCH_BODY) and _match_body_indent[_match_body_indent.size() - 1] == current_indent


func _merge_into_array(items: Array) -> Array:
	var array = []
	for item in items:
		if item is Array:
			array.append_array(item)
		else:
			array.append(item)

	return array
