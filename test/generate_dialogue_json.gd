extends Node

var Parser = preload("res://addons/clyde/parser/Parser.gd")

const FILE_PATH = "res://test/dialogue_samples/logic.clyde"
const OUTPUT_PATH = "res://generated.json"

func _ready():
	var json
	if FILE_PATH:
		var file = FileAccess.open(FILE_PATH,FileAccess.READ)
		json = parse(file.get_as_text())

	if OUTPUT_PATH:
		var save = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
		save.store_string(JSON.stringify(json))


func parse(input):
	var parser = Parser.new()
	return parser.parse(input)
