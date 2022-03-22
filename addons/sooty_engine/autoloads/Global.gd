@tool
extends Node

signal message(type: String, payload: Variant)
signal pre_scene_changed()
signal scene_changed()

@onready var config := Config.new("res://config.cfg")

var window_width: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_width")

var window_height: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_height")

var window_size: Vector2:
	get: return Vector2(window_width, window_height)

var window_aspect: float:
	get: return float(window_width) / float(window_height)

var scene_id: String:
	get: return UFile.get_file_name(get_tree().current_scene.scene_file_path)

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
	
	# call the start function
	await get_tree().process_frame
	var scene := get_tree().current_scene
	scene_changed.emit()
	if scene.has_method("_start"):
		scene._start(false)

# change scene with signals, and call start function
func change_scene(path: String, is_loading: bool):
	if get_tree().change_scene(path) == OK:
		pass
	
	pre_scene_changed.emit()
	await get_tree().process_frame
	var scene := get_tree().current_scene
	scene_changed.emit()
	if scene.has_method("_start"):
		scene._start(is_loading)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	if event.is_action_pressed("reload_scene"):
		get_tree().reload_current_scene()

func notify(msg: Dictionary):
	message.emit("notification", msg)

func call_group(group: String, fname: String, args := []):
	match len(args):
		0: return get_tree().call_group(group, fname)
		1: return get_tree().call_group(group, fname, args[0])
		2: return get_tree().call_group(group, fname, args[0], args[1])
		3: return get_tree().call_group(group, fname, args[0], args[1], args[2])
		4: return get_tree().call_group(group, fname, args[0], args[1], args[2], args[3])
		_: push_error("Not implemented.")
		
func call_group_flags(flags: int, group: String, fname: String, args := []):
	match len(args):
		0: return get_tree().call_group_flags(flags, group, fname)
		1: return get_tree().call_group_flags(flags, group, fname, args[0])
		2: return get_tree().call_group_flags(flags, group, fname, args[0], args[1])
		3: return get_tree().call_group_flags(flags, group, fname, args[0], args[1], args[2])
		4: return get_tree().call_group_flags(flags, group, fname, args[0], args[1], args[2], args[3])
		_: push_error("Not implemented.")
