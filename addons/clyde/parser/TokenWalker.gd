extends RefCounted

signal unexpected_token_detected(message: Dictionary)

const Lexer = preload('./Lexer.gd')

var _tokens
var current_token
var _lookadhed_tokens = []


func set_tokens(tokens):
	_tokens = tokens


func consume(expected = null):
	if _lookadhed_tokens.size() == 0:
		_lookadhed_tokens.push_back(_tokens.next())

	var lookahead = _lookadhed_tokens.pop_front()

	if expected != null and (lookahead == null or not expected.has(lookahead.token)):
		_wrong_token_error(lookahead, expected)

	current_token = lookahead;
	return current_token


func peek(expected = null, offset = 0):
	while _lookadhed_tokens.size() < (offset + 1):
		var token = _tokens.next();
		if token:
			_lookadhed_tokens.push_back(token);
		else:
			break

	var lookahead = _lookadhed_tokens[offset] if _lookadhed_tokens.size() > offset else null

	if expected == null || (lookahead != null and expected.has(lookahead.token)):
		return lookahead


func has_next(expected = null, offset = 0) -> bool:
	return peek(expected, offset) != null


func _wrong_token_error(token, expected):
	var expected_hints = []
	for e in expected:
		expected_hints.push_back(Lexer.get_token_friendly_hint(e))

	var error = "Unexpected token \"%s\" on line %s column %s. Expected %s" % [
		Lexer.get_token_friendly_hint(token.token),
		token.line+1,
		token.column+1,
		expected_hints
	]

	unexpected_token_detected.emit({
		"reason": "unexpected_token",
		"message": error,
		"line": token.line,
		"column": token.column,
		"friendly_token_name": Lexer.get_token_friendly_hint(token.token),
		"expected_hints": expected_hints,
	})

	assert(false, error)
