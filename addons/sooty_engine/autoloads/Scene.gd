@tool
extends Node

signal pre_scene_changed()
signal scene_changed()
var current: Node
var scenes := {}
var _iter_current := 0

var id: String:
	get: return UFile.get_file_name(current.scene_file_path)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	Mods.load_all.connect(_load_mods)
	
	# call the start function when testing from editor
	await get_tree().process_frame
	
	current = get_tree().current_scene
	scene_changed.emit()
	if current.has_method("_start"):
		current._start(false)

func _get(property: StringName):
	if current and current.has_method("_has") and current._has(property):
		return current[property]

func _set(property: StringName, value) -> bool:
	if current and current.has_method("_has") and current._has(property):
		current[property] = value
		return true
	return false

func get_main_scene_ids(sort := true) -> Array:
	var ids := Array(UFile.get_files("res://scenes", [".tscn", ".scn"])).map(func(x): return UFile.get_file_name(x))
	if sort:
		ids.sort()
	return ids

func has(id: String) -> bool:
	return id in scenes

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

func goto(id: String, kwargs := {}):
	if id in scenes:
		DialogueStack.halt(self)
		Fader.create(
			change.bind(scenes[id]),
			DialogueStack.unhalt.bind(self))
	else:
		UString.push_error_similar("Couldn't find scene '%s'." % id, id, scenes.keys())

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
	
	pre_scene_changed.emit()
	await tree.process_frame
	current = tree.current_scene
	scene_changed.emit()
	if current.has_method("_start"):
		current._start(is_loading)

func _load_mods(mods: Array):
	scenes.clear()
	for mod in mods:
		mod.meta["scenes"] = []
		for scene_path in UFile.get_files(mod.dir.plus_file("scenes"), [".scn", ".tscn"]):
			scenes[UFile.get_file_name(scene_path)] = scene_path
			mod.meta.scenes.append(scene_path)
