tool
extends EditorImportPlugin

const Parser = preload("./parser/Parser.gd")
const ClydeResult = preload("./importer/clyde_result.gd")

func get_importer_name():
	return "clyde.dialogue"

func get_visible_name():
	return "Clyde Dialogue Importer"

func get_recognized_extensions():
	return ["clyde"]

func get_save_extension():
	return "res"

func get_resource_type():
	return "PackedDataContainer"

func get_preset_count():
	return 1

func get_preset_name(i):
	return "Default"

func get_import_options(i):
	return true

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, platform_variants, gen_files):
	var file = File.new()
	file.open(source_file, File.READ)
	var clyde = file.get_as_text()
	var result = parse(clyde)

	var container = ClydeResult.new()
	container.set_data(result)

	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], container)


func parse(input):
	var parser = Parser.new()
	return parser.parse(input)
