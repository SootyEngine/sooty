@tool
extends Node

func _init() -> void:
	add_to_group("sa:scene")

func _ready() -> void:
	DialogueParser.parse("res://dialogue/test.soot")

func scene(id: String):
	
	for child in $scene.get_children():
		child.queue_free()
	
	for p in ["res://story_scenes/%s.tscn", "res://story_scenes/%s.scn"]:
		var path: String = p % id
		if UFile.file_exists(path):
			var sc: PackedScene = load(path)
			var n := sc.instantiate()
			$scene.add_child(n)