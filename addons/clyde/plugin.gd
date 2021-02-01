tool
extends EditorPlugin

const ImportPlugin = preload("import_plugin.gd")

var _import_plugin

func _enter_tree():
	_import_plugin = ImportPlugin.new()
	add_import_plugin(_import_plugin)


func _exit_tree():
	remove_import_plugin(_import_plugin)
	_import_plugin = null
