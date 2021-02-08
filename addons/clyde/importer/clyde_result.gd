extends PackedDataContainer

func set_data(data):
	__data__ = JSON.print(data).to_utf8()
	return OK

func get_content():
	var data = __data__.get_string_from_utf8()
	var parsed_json = JSON.parse(data)

	if OK != parsed_json.error:
		var format = [parsed_json.error_line, parsed_json.error_string]
		var error_string = "%d: %s" % format
		printerr("Could not parse json", error_string)
		return null

	return parsed_json.result
