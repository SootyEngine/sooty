extends Resource
class_name ModInfo
func get_class() -> String:
	return "ModInfo"

@export var dir := ""
@export var name := ""
@export var desc := ""
@export var author := "~"
@export var version := "0.0"
@export var priority := 0

@export var installed := false

@export var meta := {}

func _init(d: String, inst: bool):
	dir = d
	installed = inst
	
	if d == "res://":
		name = "res://"
	elif d.begins_with("res://addons/"):
		name = d.trim_prefix("res://addons/")
	else:
		name = d
	
	# try find .soda file
	var info_path := dir.plus_file("mod.soda")
	if UFile.file_exists(info_path):
		var data: Dictionary = DataParser.new().parse(info_path).data
		DataParser.patch(self, data, [info_path])
	# try find .cfg file
	elif UFile.file_exists(dir.plus_file("mod.cfg")):
		var cfg := ConfigFile.new()
		cfg.load(dir.plus_file("mod.cfg"))
		name = cfg.get_value("info", "name", name)
		desc = cfg.get_value("info", "desc", desc)
		author = cfg.get_value("info", "author", author)
		version = cfg.get_value("info", "version", version)
		priority = cfg.get_value("info", "priority", priority)

func get_priority() -> int:
	return (-10000 if dir.begins_with("res://") else 10000) + priority

func get_file_ids(dir: String, exts: Variant) -> Dictionary:
	var out := {}
	var head := dir.plus_file(dir) + "/"
	for file in UFile.get_files(head, exts):
		var file_id := UFile.trim_extension(file.trim_prefix(head))
		out[file_id] = file
	meta[dir] = out.keys()
	return out
