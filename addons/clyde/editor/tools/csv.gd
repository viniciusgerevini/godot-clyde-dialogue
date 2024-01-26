extends RefCounted

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")

var _settings = Settings.new()

func create_csv_file(file_path: String, parsed_document: Dictionary) -> bool:
	var options = {
		"include_metadata": _settings.get_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_METADATA, false),
		"delimiter": _settings.get_project_config(_settings.CSV_EXPORTER_CFG_DELIMITER, ","),
		"locale": _settings.get_project_config(_settings.CSV_EXPORTER_CFG_HEADER_LOCALE, InterfaceText._loaded_locale),
		"include_header": _settings.get_project_config(_settings.CSV_EXPORTER_CFG_INCLUDE_HEADER, true)
	}

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

	if not file.is_open():
		return false

	if options.include_header:
		_add_header_line(file, options)

	_store_lines(parsed_document, file, options)
	file.flush()
	return true


func _add_header_line(file: FileAccess, options: Dictionary):
	var columns = [
		"id",
		options.locale,
	]

	if options.include_metadata:
		columns.push_back("metadata")

	file.store_csv_line(columns, options.delimiter)


func _store_lines(next, file: FileAccess, options: Dictionary):
	if next is Array:
		for n in next:
			_store_lines(n, file, options)
		return
	match next.type:
		"document":
			_store_lines(next.content, file, options)
			_store_lines(next.blocks, file, options)
		"content", "variations", "action_content", "conditional_content", "block":
			_store_lines(next.content, file, options)
		"line":
			_store_line(next, file, options)
		"options":
			if next.name != null:
				_store_options_node(next, file, options)
				return
			_store_lines(next.content, file, options)
		"option":
			_store_option_node(next, file, options)


func _store_options_node(node: Dictionary, file: FileAccess, options: Dictionary):
	_store_line({
		"id": node.id,
		"value": node.name,
		"speaker": node.speaker,
		"tags": node.tag,
	}, file, options)

	_store_lines(node.content, file, options)


func _store_option_node(node: Dictionary, file: FileAccess, options: Dictionary):
	# handle display only options
	if (
		(node.content.content == null or node.content.content.size() == 0) or
		node.content.content[0].id != node.id
	):
		_store_options_node(node, file, options)
		return

	_store_lines(node.content, file, options)


func _store_line(line: Dictionary, file: FileAccess, options: Dictionary):
	if line.id == null:
		return

	var columns = [
		line.id,
		line.value
	]

	if options.include_metadata:
		var metadata = []
		if line.speaker != null:
			metadata.push_back("speaker: %s" % line.speaker)
		if not line.tags.is_empty():
			metadata.push_back("tags: %s" % " ".join(line.tags))

		columns.push_back(" ".join(metadata))

	file.store_csv_line(columns, options.delimiter)
