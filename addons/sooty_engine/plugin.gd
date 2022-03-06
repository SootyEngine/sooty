@tool
extends EditorPlugin

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
