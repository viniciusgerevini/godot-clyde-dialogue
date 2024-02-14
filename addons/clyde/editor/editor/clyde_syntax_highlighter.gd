@tool
extends SyntaxHighlighter

const Lexer = preload("../../parser/Lexer.gd")

var _lexer = Lexer.new()

var _cache = {}

const _logic_english_operators = [ "and", "or", "not", "is", "isnt" ]
const _logic_operators_and_symbols = [ "=", "*", "/", "+", "-", "?", ",", "<", ">", "|", "%", "&" ]
const _logic_keywords = [ "set", "when", "trigger" ]
const _options = [ "*", "+", ">" ]

var _escapable_chars_regex = RegEx.create_from_string("[\\\\|\\*\\+\\>\\%\\(\\)\\{\\}\\\"\\'\\$\\#\\:]")
var _variations_mode_regex = RegEx.create_from_string("^([\\s\\t]*)(cycle|once|sequence|shuffle(\\s+(once|cycle|sequence))?)([\\s\\t]*)$")
var _tag_regex = RegEx.create_from_string("[A-z0-9\\-\\_\\.]")
var _leading_spaces_regex = RegEx.create_from_string("^\\s*")

var _config = {}

func _clear_highlighting_cache():
	_cache = {}


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var editor: TextEdit = get_text_edit()
	var content: String = editor.get_line(line)
	_config = editor.editor_theme_config

	return _get_regions(content, line)


func _get_regions(content: String, line_number: int) -> Dictionary:
	var current_column := 0
	var regions := {}

	var cached = _get_from_cache(line_number, content)
	if cached != null and not _has_previous_line_changed(line_number, cached):
		return cached.regions

	var is_in_logic_mode = false
	var is_in_variation_mode = false
	var is_in_quote_mode = false
	var quote_char = ""
	var was_last_region_text = true
	var has_divert = false

	var uninterrupted_text = ""
	var is_speaker_allowed = true

	var prev_q_mode = false
	var prev_l_mode = false
	var prev_v_mode = false

	if line_number > 0:
		var previous_line = _get_from_cache(line_number - 1)
		if previous_line != null:
			is_in_quote_mode = previous_line.meta.on_q_mode
			is_in_logic_mode = previous_line.meta.on_l_mode
			is_in_variation_mode = previous_line.meta.on_v_mode
			quote_char = previous_line.meta.quote_char
			prev_q_mode = previous_line.meta.on_q_mode
			prev_l_mode = previous_line.meta.on_l_mode
			prev_v_mode = previous_line.meta.on_v_mode

	if content.begins_with("--"):
		regions[current_column] = _comment_region()
		_set_cache(line_number, content, regions, {
			"on_q_mode": is_in_quote_mode,
			"on_l_mode": is_in_logic_mode,
			"on_v_mode": is_in_variation_mode,
			"has_divert": has_divert,
			"quote_char": quote_char,
			"prev_on_q_mode": prev_q_mode,
			"prev_on_l_mode": prev_l_mode,
			"prev_on_v_mode": prev_v_mode,
		})
		return regions

	var is_first_content_in_line = true

	while current_column < content.length():
		var has_no_text_content = uninterrupted_text.strip_edges().is_empty()

		if not (is_in_quote_mode or is_in_logic_mode) and _was_escaped(content, current_column):
			regions[current_column - 1] = _comment_region()
			regions[current_column] = _text_region()
			current_column += 1
			was_last_region_text = false
			continue

		# logic blocks
		if is_in_logic_mode:
			var result = _handle_logic_mode(content, current_column, has_no_text_content, regions)
			is_in_logic_mode = result.is_in_logic_mode
			current_column = result.current_column
			is_speaker_allowed = result.is_speaker_allowed
			was_last_region_text = false
			continue

		# logic block start
		if not is_in_quote_mode and content[current_column] == "{":
			is_in_logic_mode = true
			regions[current_column] = _symbol_region()
			was_last_region_text = false
			current_column += 1
			is_speaker_allowed = false
			continue

		# line in quotes
		if is_in_quote_mode or (has_no_text_content and (content[current_column] == "\"" or content[current_column] == "\'")):
			var result = _handle_quote_mode(content, current_column, regions, is_in_quote_mode, quote_char)
			is_in_quote_mode = result.is_in_quote_mode
			current_column = result.current_column
			quote_char = result.quote_char
			was_last_region_text = false
			is_speaker_allowed = false
			continue

		# variation start
		if has_no_text_content and content[current_column] == "(":
			var result = _handle_variation_mode_start(content, current_column, regions)
			is_in_variation_mode = true
			current_column = result.current_column
			was_last_region_text = false
			is_speaker_allowed = false
			continue

		# variation end
		if is_in_variation_mode and content[current_column] == ")":
			regions[current_column] = _symbol_region()
			current_column += 1
			was_last_region_text =  false
			is_in_variation_mode = false
			continue

		if is_in_variation_mode and has_no_text_content and content[current_column] == "-":
			regions[current_column] = _operator_region()
			current_column += 1
			was_last_region_text = false
			continue

		# speaker
		if content[current_column] == ":" and is_speaker_allowed:
			if not has_no_text_content:
				var leading_spaces = _leading_spaces_regex.search(uninterrupted_text)
				regions[current_column - uninterrupted_text.length() + leading_spaces.get_end()] = _identifier_region()
				was_last_region_text = false
				current_column += 1
				is_speaker_allowed = false
				uninterrupted_text = ""
				continue

		if is_first_content_in_line:
			# options
			if _options.has(content[current_column]):
				regions[current_column] = _operator_region()
				was_last_region_text = false
				current_column += 1
				is_first_content_in_line = false
				is_speaker_allowed = true
				continue
		# display option
		elif content[current_column] == "=" and _options.has(content[current_column - 1]):
			current_column += 1
			continue

		# tags
		if content[current_column] == "#":
			var result = _handle_tag(content, current_column, regions)
			current_column = result.current_column
			is_speaker_allowed = false
			is_first_content_in_line = false
			was_last_region_text = false
			continue

		# ids
		if content[current_column] == "$":
			var result = _handle_line_id(content, current_column, regions)
			current_column = result.current_column
			is_speaker_allowed = false
			is_first_content_in_line = false
			was_last_region_text = false
			continue

		# interpolation
		if content[current_column] == "%":
			var result = _handle_var_interpolation(content, current_column, regions)
			current_column = result.current_column
			was_last_region_text = false
			continue

		if current_column > 0:
			var is_mid_text = uninterrupted_text.strip_edges().length() > 2

			if not is_mid_text:
				# divert
				if content[current_column] == ">" and content[current_column - 1] == "-":
					regions[current_column - 1] = _operator_region()
					current_column += 1
					# proactively sets the rest of the line as identifier
					if current_column < content.length() -1:
						regions[current_column] = _text_region()
						regions[current_column + 1] = _identifier_region()
					has_divert = true
					continue

			#  divert to parent
			if (not is_mid_text or has_divert) and content[current_column] == "-" and content[current_column - 1] == "<":
				regions[current_column - 1] = _operator_region()
				current_column += 1
				was_last_region_text = false
				continue

		# blocks
		if content[current_column] == "=" and current_column == 0 and content.length() > 1:
			if content[current_column + 1] == "=":
				regions[current_column] = _operator_region()
				current_column += 2
				if current_column < content.length():
					regions[current_column + 1] = _identifier_region()
				continue

		if not was_last_region_text:
			regions[current_column] = _text_region()
			was_last_region_text = true

		uninterrupted_text += content[current_column]

		if content[current_column] != " " and content[current_column] != "\t":
			is_first_content_in_line = false

		current_column += 1

	_set_cache(line_number, content, regions, {
		"on_q_mode": is_in_quote_mode,
		"on_l_mode": is_in_logic_mode,
		"on_v_mode": is_in_variation_mode,
		"quote_char": quote_char,
		"has_divert": has_divert,
		"prev_on_q_mode": prev_q_mode,
		"prev_on_l_mode": prev_l_mode,
		"prev_on_v_mode": prev_v_mode,
	})

	return regions;


func _get_from_cache(line: int, content = null):
	var cached = _cache.get(line)
	if cached == null:
		return
	if content == null:
		return cached
	if content == cached.content:
		return cached

func _set_cache(line, content, regions, meta = _default_meta()):
	_cache[line] = _cache_entry(content, regions, meta)


func _cache_entry(content: String, regions: Dictionary, meta) -> Dictionary:
	return {
		"content": content,
		"regions": regions,
		"meta": meta,
	}


func _default_meta():
	return {
		"on_q_mode": false,
		"on_l_mode": false,
		"on_v_mode": false,
		"quote_char": "",
		"prev_on_q_mode": false,
		"prev_on_l_mode": false,
		"prev_on_v_mode": false,
		"has_divert": false,
	}


func _has_previous_line_changed(line_number: int, cached: Dictionary) -> bool:
	if (line_number == 0):
		return false

	var previous_line = _get_from_cache(line_number - 1)
	if previous_line == null:
		return false

	return (
		previous_line.meta.on_q_mode != cached.meta.prev_on_q_mode ||
		previous_line.meta.on_l_mode != cached.meta.prev_on_l_mode ||
		previous_line.meta.on_v_mode != cached.meta.prev_on_v_mode
	)


func _handle_logic_mode(content: String, current_column: int, no_previous_text: bool, regions: Dictionary):
	while current_column < content.length():
		var character = content[current_column]

		if character == "\"" or character == "'":
			current_column = _handle_logic_string_literal(current_column, content, regions)
			continue

		# handle numbers
		if character.is_valid_int():
			current_column = _handle_logic_number_literal(current_column, content, regions)
			continue

		# handle identifiers, keywords and literals
		if character.is_valid_identifier():
			current_column = _handle_logic_regular_chars(current_column, content, regions)
			continue

		# operators and symbols
		if _logic_operators_and_symbols.has(character):
			regions[current_column] = _operator_region()
			current_column += 1
			regions[current_column] = _text_region()
			continue

		# logic block end
		if character == "}":
			regions[current_column] = _symbol_region()
			current_column += 1
			return {
				"is_in_logic_mode": false,
				"current_column": current_column,
				"is_speaker_allowed": no_previous_text
			}

		# increment for any unrecognizable character inside the block
		current_column += 1

	return {
		"is_in_logic_mode": true,
		"current_column": current_column,
		"is_speaker_allowed": no_previous_text
	}


func _handle_logic_number_literal(current_column: int, content: String, regions: Dictionary) -> int:
	var init_column = current_column
	var character = content[current_column]
	while character == '.' or character.is_valid_int():
		current_column += 1
		if current_column < content.length() - 1:
			character = content[current_column]
		else:
			break
	regions[init_column] = _number_literal_region()
	return current_column


func _handle_logic_regular_chars(current_column: int, content: String, regions: Dictionary) -> int:
	var init_column = current_column
	var value = ""
	while current_column < content.length():
		var character = content[current_column]
		var updated_value = value + character
		if not updated_value.is_valid_identifier():
			break
		value = updated_value
		current_column += 1

	if _logic_english_operators.has(value) or _logic_keywords.has(value):
		regions[init_column] = _keyword_region()
	elif ["true", "false"].has(value):
		regions[init_column] = _boolean_literal_region()
	else:
		regions[init_column] = _identifier_region()
	regions[init_column + value.length()] = _text_region()

	return current_column


func _handle_logic_string_literal(current_column: int, content: String, regions: Dictionary) -> int:
	regions[current_column] = _string_literal_region()
	var opening_quote = content[current_column]
	current_column += 1
	while current_column < content.length():
		if content[current_column] == opening_quote:
			current_column += 1
			break
		current_column += 1

	return current_column


func _handle_quote_mode(content: String, current_column: int, regions: Dictionary, is_in_quote_mode: bool, quote_char: String) -> Dictionary:
	if not is_in_quote_mode:
		is_in_quote_mode = true
		quote_char = content[current_column]
		regions[current_column] = _symbol_region()
		current_column += 1

	regions[current_column] = _text_region()

	while current_column < content.length():
		if content[current_column] == quote_char:
			is_in_quote_mode = false
			regions[current_column] = _symbol_region()
			current_column += 1
			regions[current_column] = _text_region()
			break
		current_column += 1

	return {
		"is_in_quote_mode": is_in_quote_mode,
		"current_column": current_column,
		"quote_char": quote_char
	}

func _handle_variation_mode_start(content: String, current_column: int, regions: Dictionary) -> Dictionary:
	regions[current_column] = _symbol_region()
	current_column += 1
	if current_column < content.length() - 4:
		var s = content.substr(current_column)
		var result = _variations_mode_regex.search(s)
		if result != null:
			regions[current_column + result.get_start(2)] = _keyword_region()
			if result.get_start(3) != -1:
				regions[current_column + result.get_start(3)] =_text_region()
			if result.get_start(4) != -1:
				regions[current_column + result.get_start(4)] = _keyword_region()
			if result.get_start(5) != -1:
				regions[current_column + result.get_start(5)] = _text_region()

			return { "current_column": current_column + result.get_end() }

	return {
		"current_column": current_column,
	}


func _handle_tag(content: String, current_column: int, regions: Dictionary) -> Dictionary:
	regions[current_column] = _tag_region()
	current_column += 1
	while (current_column < content.length()):
		if _tag_regex.search(content[current_column]) == null:
			regions[current_column] = _text_region()
			current_column += 1
			break
		current_column += 1
	return { "current_column": current_column }


func _handle_line_id(content: String, current_column: int, regions: Dictionary) -> Dictionary:
	var regex = RegEx.create_from_string("[A-z0-9\\-\\_&]")
	regions[current_column] = _identifier_region()
	current_column += 1
	while (current_column < content.length()):
		if regex.search(content[current_column]) == null:
			current_column += 1
			break
		current_column += 1
	return { "current_column": current_column }


func _handle_var_interpolation(content: String, current_column: int, regions: Dictionary) -> Dictionary:
	var regex = RegEx.create_from_string("^\\%[A-z0-9_]+\\%")
	var remaining_content = content.substr(current_column)
	var result = regex.search(remaining_content)
	if result != null:
		regions[current_column] = _identifier_region()
		return { "current_column": current_column + result.get_end() }
	current_column += 1
	return { "current_column": current_column }


func _identifier_region():
	return { "color": _config.color_scheme.identifier}


func _comment_region():
	return { "color": _config.color_scheme.comment }


func _symbol_region():
	return { "color": _config.color_scheme.symbol }


func _text_region():
	return { "color": _config.color_scheme.text }


func _tag_region():
	return { "color": _config.color_scheme.tag }


func _keyword_region():
	return { "color": _config.color_scheme.keyword }


func _operator_region():
	return { "color": _config.color_scheme.operator }


func _number_literal_region():
	return { "color": _config.color_scheme.number_literal }


func _boolean_literal_region():
	return { "color": _config.color_scheme.boolean_literal }


func _string_literal_region():
	return { "color": _config.color_scheme.string_literal }


func _was_escaped(content: String, current_column: int) -> bool:
	return (
		content.length() > 1 and
		content[current_column - 1] == "\\" and
		_can_be_escaped(content[current_column])
	)


func _can_be_escaped(character: String) -> bool:
	return _escapable_chars_regex.search(character) != null
