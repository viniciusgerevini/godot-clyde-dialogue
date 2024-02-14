extends "res://addons/clyde/helpers/bubbles/dialogue_bubble.gd"


func set_speaker(content: Dictionary):
	if content.get("variables", {}).has("name"):
		_speaker_field.text = content.variables.name
		_speaker_field.show()

	if not content.has("bubble_position"):
		printerr("bubble_position not defined in speaker data. Floating bubble won't work correctly.")

	# in case your camera is not static you might need to do this in the _process() hook so the
	# position is kept updated
	position = content.bubble_position.get_global_transform_with_canvas().origin

