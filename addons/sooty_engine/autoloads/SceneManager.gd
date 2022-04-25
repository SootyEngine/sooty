@tool
extends Node

signal pre_changed()
signal changed()

var scenes := {}
var scenes_ui := {}
var active_ui := {}
var _goto: Callable # an overridable goto function, so you can use your own transition system.

func _ready() -> void:
	var _sooty := get_node("/root/Sooty")
	_sooty.actions.connect_as_node(self, "SceneManager")
	_sooty.actions.connect_methods(self, [goto_scene, scene_id, show_ui, toggle_ui])
	_sooty.mods.load_all.connect(_load_mods)
	if not Engine.is_editor_hint():
		# call the start function when testing from editor
		_sooty.mods.loaded.connect(_signal_changed.bind(false), CONNECT_ONESHOT)

func _get_method_info(method: String):
	match method:
		"goto_scene":
			return {
				args={
					id={
						# auto complete list of scenes
						options=func(): return scenes.keys(),
						icon=preload("res://addons/sooty_engine/icons/scene.png"),
					}
				}
			}

# testing
enum Transition { FADE_OUT, INSTANT }
func goto_scene(id: String, transition: Transition = Transition.FADE_OUT, kwargs := {}):
	if _goto:
		_goto.call(id, kwargs)
	else:
		change(id)
	
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

func has(id: String) -> bool:
	return id in scenes

func find(id: String) -> String:
	if id in scenes:
		return scenes[id]
	else:
		UString.push_error_similar("No scene '%s'." % [id], id, scenes.keys())
		return ""

func is_showing_ui(id: String) -> bool:
	return id in active_ui and is_instance_valid(active_ui[id]) and active_ui[id].is_inside_tree()

func toggle_ui(id: String):
	if is_showing_ui(id):
		hide_ui(id)
	else:
		show_ui(id)

func hide_ui(id: String):
	if id in active_ui and active_ui[id].is_inside_tree():
		Global.remove_child(active_ui[id])

func show_ui(id: String) -> Node:
	if id in scenes_ui:
		# has valid instance?
		if id in active_ui and is_instance_valid(active_ui[id]):
			if not active_ui[id].is_inside_tree():
				Global.add_child(active_ui[id])
			return active_ui[id]
		else:
			print("Creating ", id)
			var out: Node = load(scenes_ui[id]).instantiate()
			out.name = id
			active_ui[id] = out
			Global.add_child(out)
			return out
	else:
		push_warning("No ui '%s'. %s" % [id, scenes_ui.keys()])
		return null

func create(id: String, parent: Node = null) -> Node:
	if id in scenes:
		var out: Node = load(scenes[id]).instantiate()
		if parent:
			parent.add_child(out)
		return out
	return null

# change scene with signals, and call start function
func change(path: String, is_loading: bool = false):
	var tree := Global.get_tree()
	
	if not path.begins_with("res://") and not path.begins_with("user://"):
		if path in scenes:
			path = scenes[path]
		else:
			push_error("No scene with id '%s'." % path)
			return
	
	if tree.change_scene(path) == OK:
		pass
	
	if not is_loading:
		pre_changed.emit()
	
	_signal_changed.call_deferred(is_loading)

func _load_mods(mods: Array):
	scenes.clear()
	for mod in mods:
		# find scenes
		mod.meta["scenes"] = []
		var head: String = mod.dir.plus_file("scenes") + "/"
		for scene_path in UFile.get_files(head, [".scn", ".tscn"]):
			var scene_id: String = UFile.trim_extension(scene_path.trim_prefix(head))
			scenes[scene_id] = scene_path
			mod.meta.scenes.append(scene_id)
		
		# find ui scenes
		mod.meta["scenes_ui"] = []
		var dir_head: String = mod.dir.plus_file("scenes_ui") + "/"
		for scene_path in UFile.get_files(dir_head, [".scn", ".tscn"], true, false, 9999, 1):
			var scene_id: String = UFile.get_file_name(scene_path)
			scenes_ui[scene_id] = scene_path
			mod.meta.scenes_ui.append(scene_id)
