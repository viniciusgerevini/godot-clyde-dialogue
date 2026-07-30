extends "./context_menu_base.gd"

func _open_in_dialogue_player(files) -> void:
	for f in files:
		if f.ends_with(".clyde"):
			player_requested.emit(f)
			break


func _on_create_csv(files) -> void:
	for f in files:
		if f.ends_with(".clyde"):
			csv_exporter_requested.emit(f)
			break
