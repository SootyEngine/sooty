extends Node

signal pre_scene_changed()
signal scene_changed()
var current: Node
var scenes := {}
var _iter_current := 0

func _init() -> void:
	add_to_group("Scene")
	add_to_group("sa:goto")

func _ready() -> void:
	Mods.load_all.connect(_load_mods)
	
	# call the start function when testing from editor
	await get_tree().process_frame
	current = get_tree().current_scene
	scene_changed.emit()
	if current.has_method("_start"):
		current._start(false)

func _get(property: StringName):
	if property in current:
		return current[property]

func _set(property: StringName, value) -> bool:
	if property in current:
		current[property] = value
		return true
	return false

#func _iter_init(arg):
#	_iter_current = 0
#	return _iter_current < len(scenes)
#
#func _iter_next(arg):
#	_iter_current += 1
#	return _iter_current < len(scenes)
#
#func _iter_get(arg):
#	return scenes.keys()[_iter_current]

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
		push_error("Couldn't find scene %s." % id)

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
