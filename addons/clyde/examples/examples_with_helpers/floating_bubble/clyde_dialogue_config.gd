extends "res://addons/clyde/helpers/dialogue_config.gd"


# This is just a silly in memory persistence for demonstration.
# You should override this method with the proper persistence mechanism from your
# game.
var persistence = {}
var external_variables = {}

func _load_dialogue_data(dialogue_path: String, block_name: String) -> Dictionary:
	return persistence.get("%s_%s" % [ dialogue_path, block_name ], {})


func _persist_dialogue_data(dialogue_path: String, block_name: String, dialogue_data: Dictionary) -> void:
	persistence["%s_%s" % [ dialogue_path, block_name ]] = dialogue_data


func _on_external_variable_update(variable_name: String, value: Variant) -> void:
	external_variables[variable_name] = value


func _on_external_variable_fetch(variable_name: String) -> Variant:
	return external_variables.get(variable_name)
