@tool
extends Node
class_name FE_BaseFile

signal modified()

var path := ""
var last_path := ""
var last_modified := -1
var open_in_file_list := false

var editors: FE_Editors:
	get: return owner.editors

var file_name: String:
	get: return path.get_file()

var base_name: String:
	get: return path.get_file().rsplit(".", true, 1)[0]

func get_popup_options() -> Array:
	return []

func _init(p: String):
	path = p
	var f = p.get_file()
	if f:
		set_name(f.replace(".", "--"))
	else:
		set_name("ROOT")
	reload()

func reload():
	last_modified = File.new().get_modified_time(path)

func get_json() -> Dictionary:
	return { path=path }

func get_file_manager():
	return get_tree().current_scene.file_manager

func was_modified() -> bool:
	return last_modified != File.new().get_modified_time(path)
