@tool
extends Node

var _res := {}

func _get_res_dir() -> String:
	assert(false)
	return ""

func _get_res_extensions() -> Array:
	assert(false)
	return []

func _ready() -> void:
	var _sooty := get_node("/root/Sooty")
	_sooty.mods.load_all.connect(_load_mods)

func is_explicit_path(path: String) -> bool:
	return path.begins_with("res://") or path.begins_with("user://")

func get_all_ids() -> Array:
	return _res.keys()

func has(id: String) -> bool:
	return id in _res

func find(id: String) -> String:
	if id in _res:
		return _res[id]
	else:
		UString.push_error_similar("No %s '%s'." % [_get_res_dir(), id], id, _res.keys())
		return ""

func _load_mods(mods: Array):
	# clear old
	_res.clear()
	
	for mod in mods:
		UDict.merge(_res, mod.get_file_ids(_get_res_dir(), _get_res_extensions()))
#		var head: String = mod.dir.plus_file(res_dir) + "/"
#		var all_files := UFile.get_files(head, _get_res_extensions())
#		mod.meta[res_dir] = all_files
#		for scene_path in all_files:
#			var id: String = UFile.trim_extension(scene_path.trim_prefix(head))
#			_res[id] = scene_path
