extends RefCounted

const Lexer = preload("../../parser/Lexer.gd")

var _options_token := [
	Lexer.TOKEN_OPTION, Lexer.TOKEN_STICKY_OPTION, Lexer.TOKEN_FALLBACK_OPTION
]

var _quotes := [ "'", '"']

func add_ids_to_content(content: String) -> String:
	var lexer = Lexer.new()
	var tokens = lexer.init(content).get_all()
	var lines = content.split("\n")

	var i = 0
	while true:
		if i >= tokens.size():
			break
		var token = tokens[i]
		var id_position

		if _options_token.has(token.token):
			var offset
			for j in range(i + 1, tokens.size()):
				offset = j
				if tokens[offset].token == Lexer.TOKEN_TEXT:
					break
			id_position = _find_position_for_id(tokens, offset, false)
		elif token.token == Lexer.TOKEN_TEXT:
			id_position = _find_position_for_id(tokens, i)


		if id_position != null:
			if not id_position.id_found:
				var line = lines[id_position.line]

				if id_position.start_column > 0 and _quotes.has(line[id_position.start_column - 1]):
					if line.length() > id_position.column:
						id_position.column += 1
					else: # this means the quotted text has line breaks
						id_position.column = id_position.column - line.length()
						id_position.line += 1
						line = lines[id_position.line]
				lines[id_position.line] = _add_at(line, " $%s" % _generate_id(), id_position.column)
			i = id_position.index
		i += 1

	return "\n".join(lines)



func _find_position_for_id(tokens: Array, starting_pos: int, allow_indent: bool = true):
	var place_token = tokens[starting_pos]
	var index = starting_pos
	var allow_text = false
	var id_found = false
	for i in range(starting_pos + 1, tokens.size()):
		var token = tokens[i]
		if allow_indent and token.token == Lexer.TOKEN_INDENT:
			allow_text = true
			index = i
			continue

		if token.token == Lexer.TOKEN_LINE_ID:
			index = i
			id_found = true
		elif token.token == Lexer.TOKEN_TEXT and allow_text:
			index = i
			place_token = token
		elif token.token != Lexer.TOKEN_TAG:
			break

	return {
		"line": place_token.line,
		"column": place_token.column + place_token.value.length(),
		"start_column": place_token.column,
		"index": index,
		"id_found": id_found
	}

func _add_at(text: String, extra_content: String, position: int) -> String:
	return text.insert(position, extra_content)


func _generate_id() -> String:
	return "ID%s" % ResourceUID.create_id()
