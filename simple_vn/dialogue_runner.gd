@tool
extends Node

func _init() -> void:
	add_to_group("sa:scene")

func _ready() -> void:
	DialogueParser.parse("res://dialogue/test.soot")

func scene(id: String):
	# remove previous scenes
	for child in $scene.get_children():
		$scene.remove_child(child)
		child.queue_free()
	
	var sc := find_scene(id)
	if sc:
		$scene.add_child(sc.instantiate())
	else:
		push_error("No scene '%s' found." % id)

func find_scene(id: String) -> PackedScene:
	for p in ["res://story_scenes/%s.tscn", "res://story_scenes/%s.scn"]:
		var path: String = p % id
		if UFile.file_exists(path):
			return load(path)
	return null
	
