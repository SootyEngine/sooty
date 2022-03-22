extends Resource
class_name ModInfo

func get_class() -> String:
	return "ModInfo"

var dir := ""
var name := ""
var author := ""
var version := ""
var priority := 0

var installed := false

var meta := {}

func _init(d: String, inst: bool):
	dir = d
	installed = inst
	
	if d == "res://":
		name = "BASE_GAME_STATE"
	elif d.begins_with("res://addons/"):
		name = d.trim_prefix("res://addons/")
	else:
		name = d
	
	author = "~"
	version = "0.0"
	
	var info_path := dir.plus_file("info.cfg")
	if UFile.file_exists(info_path):
		var cfg := ConfigFile.new()
		cfg.load(info_path)
		name = cfg.get_value("info", "name", "NO_NAME")
		author = cfg.get_value("info", "author", "NO_AUTHOR")
		version = cfg.get_value("info", "version", "NO_VERSION")
		priority = cfg.get_value("info", "priority", 0)
	
	prints(name, author, version, get_priority())

func get_priority() -> int:
	return (-10000 if dir.begins_with("res://") else 10000) + priority
