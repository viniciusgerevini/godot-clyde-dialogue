extends "./context_menu_base.gd"

func _open_in_dialogue_player(files) -> void:
	for f in files:
		if f.ends_with(".clyde"):
			player_requested.emit(f)
			break
