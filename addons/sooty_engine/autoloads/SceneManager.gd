@tool
extends Node

signal pre_changed()
signal changed()

var scenes := {}
var _goto: Callable # an overridable goto function, so you can use your own transition system.

func _get_method_info(method: String):
	if method == "scene":
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
func scene(id: String, transition: Transition = Transition.FADE_OUT, kwargs := {}):
	if _goto:
		_goto.call(id, kwargs)
	else:
		change(id)

func _ready() -> void:
	await get_tree().process_frame
	
	StringAction.connect_as_node(self, "SceneManager")
	StringAction.connect_methods(self, [scene])
	
	ModManager.load_all.connect(_load_mods)
	if not Engine.is_editor_hint():
		# call the start function when testing from editor
		ModManager.loaded.connect(_signal_changed.bind(false), CONNECT_ONESHOT)

func _signal_changed(is_loading: bool):
	if not is_loading:
		changed.emit()

#func _get(property: StringName):
#	var current := get_tree().current_scene
#	if current and current.has_method("_has") and current._has(property):
#		return current[property]
#
#func _set(property: StringName, value) -> bool:
#	var current := get_tree().current_scene
#	if current and current.has_method("_has") and current._has(property):
#		current[property] = value
#		return true
#	return false

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

func create(id: String, parent: Node = null) -> Node:
	if id in scenes:
		var out: Node = load(scenes[id]).instantiate()
		if parent:
			parent.add_child(out)
		return out
	return null

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		set_process_input(false)
		return
	
	if event.is_action_pressed("reload_scene"):
		get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()

# change scene with signals, and call start function
func change(path: String, is_loading: bool = false):
	var tree := get_tree()
	
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
#	await tree.process_frame
	_signal_changed.call_deferred(is_loading)

func _load_mods(mods: Array):
	scenes.clear()
	for mod in mods:
		mod.meta["scenes"] = []
		var head: String = mod.dir.plus_file("scenes") + "/"
		for scene_path in UFile.get_files(head, [".scn", ".tscn"]):
			var scene_id: String = UFile.trim_extension(scene_path.trim_prefix(head))
			scenes[scene_id] = scene_path
			mod.meta.scenes.append(scene_id)
