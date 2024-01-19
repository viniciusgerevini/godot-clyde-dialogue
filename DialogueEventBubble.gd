@tool
extends VBoxContainer

func set_label(text: String, sub_label):
	$Label.text = text
	if sub_label != null:
		$SubLabel.text = "[ %s ]" % sub_label
		$SubLabel.show()
