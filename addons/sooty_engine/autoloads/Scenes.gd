@tool
extends "res://addons/sooty_engine/autoloads/ResManager.gd"

signal pre_changed()
signal changed()

signal transition_started()
signal transition_ended()

var _goto: Callable # an overridable goto function, so you can use your own transition system.

func _ready() -> void:
	super._ready()
	var _sooty := Global.get_node("/root/Sooty")
	_sooty.actions.connect_as_node(self, "Scenes")
	_sooty.actions.connect_methods([scene_id])
	if not Engine.is_editor_hint():
		# call the start function when testing from editor
		_sooty.mods.loaded.connect(_signal_changed.bind(false), CONNECT_ONESHOT)

func is_current_a_scene() -> bool:
	return Global.get_tree().current_scene.scene_file_path in _res.values()

# the current scen name
func scene_id() -> String:
	return UFile.get_file_name(Global.get_tree().current_scene.scene_file_path)

func _signal_changed(is_loading: bool):
	if not is_loading:
		changed.emit()

func get_main_scene_ids(sort := true) -> Array:
	var ids := Array(UFile.get_files("res://scenes", [".tscn", ".scn"])).map(func(x): return UFile.get_file_name(x))
	if sort:
		ids.sort()
	return ids

func create(id: String, parent: Node = null) -> Node:
	var path := find(id)
	if path:
		var out: Node = load(path).instantiate()
		if parent:
			prints(id, path)
			parent.add_child(out)
		return out
	return null

func _get_method_info(method: String):
	match method:
		"change":
			return {
				args={
					path={
						# auto complete list of scenes
						options=get_all_ids,
						icon=preload("res://addons/sooty_engine/icons/scene.png"),
					}
				}
			}

# change scene with signals, and call start function
func change(path: String, is_loading: bool = false):
	var tree := Global.get_tree()
	
	# treat as id
	if not is_explicit_path(path):
		path = find(path)
		if path == "":
			return
	
	if tree.change_scene(path) == OK:
		pass
	
	if not is_loading:
		pre_changed.emit()
	
	_signal_changed.call_deferred(is_loading)

func _get_res_dir() -> String:
	return "scenes"

func _get_res_extensions() -> Array:
	return [".scn", ".tscn"]

#func _load_mods(mods: Array):
#	scenes.clear()
#	for mod in mods:
#		# find scenes
#		mod.meta["scenes"] = []
#		var head: String = mod.dir.plus_file("scenes") + "/"
#		for scene_path in UFile.get_files(head, [".scn", ".tscn"]):
#			var scene_id: String = UFile.trim_extension(scene_path.trim_prefix(head))
#			scenes[scene_id] = scene_path
#			mod.meta.scenes.append(scene_id)
#
#		# find ui scenes
#		mod.meta["scenes_ui"] = []
#		var dir_head: String = mod.dir.plus_file("scenes_ui") + "/"
#		for scene_path in UFile.get_files(dir_head, [".scn", ".tscn"], true, false, 9999, 1):
#			var scene_id: String = UFile.get_file_name(scene_path)
#			scenes_ui[scene_id] = scene_path
#			mod.meta.scenes_ui.append(scene_id)
