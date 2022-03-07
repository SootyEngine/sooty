@tool
extends Node

func _init() -> void:
	add_to_group("sa:scene")

func scene(id: String):
	for child in $scene.get_children():
		child.queue_free()
	
	for p in ["res://story_scenes/%s.tscn", "res://story_scenes/%s.scn"]:
		var path: String = p % id
		if UFile.file_exists(path):
			var scene: Node = load(path).instantiate()
			$scene.add_child(scene)
