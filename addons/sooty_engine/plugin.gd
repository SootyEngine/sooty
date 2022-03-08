@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Global", "res://addons/sooty_engine/autoloads/Global.gd")
	add_autoload_singleton("SaveManager", "res://addons/sooty_engine/autoloads/SaveManager.gd")
	add_autoload_singleton("ModManager", "res://addons/sooty_engine/autoloads/ModManager.gd")
	add_autoload_singleton("State", "res://addons/sooty_engine/autoloads/State.gd")
	add_autoload_singleton("Dialogues", "res://addons/sooty_engine/autoloads/Dialogues.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("Global")
	remove_autoload_singleton("SaveManager")
	remove_autoload_singleton("ModManager")
	remove_autoload_singleton("State")
	remove_autoload_singleton("Dialogues")
#func _enter_tree() -> void:
#	var fs := get_editor_interface().get_resource_filesystem()
#	fs.resources_reload.connect(_resources_reload)
#	fs.resources_reimported.connect(_resources_reload)
#	fs.filesystem_changed.connect(_resources_reload)
#
#	var se := get_editor_interface().get_script_editor()
#	se.editor_script_changed.connect(_resources_reload)
	
#	dialogue_importer = preload("dialogue_importer.gd").new()
#	add_import_plugin(dialogue_importer)

#func _exit_tree():
#	remove_import_plugin(dialogue_importer)
#	dialogue_importer = null

#func _resources_reload(a=null):
#	prints("DID IT", a)
