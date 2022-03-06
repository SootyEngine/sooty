@tool
extends Node

var _d := {}

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quick_save"):
		var file_path = "user://quick_save.scn"
		var scene = PackedScene.new()
		get_tree().current_scene.set_meta("STATE", State._get_changed_states())
		scene.pack(get_tree().current_scene)
		ResourceSaver.save(file_path, scene, ResourceSaver.FLAG_COMPRESS)
		get_viewport().set_input_as_handled()
		print("Quick saved to: %s." % file_path)
		
	elif Input.is_action_just_pressed("quick_load"):
		var file_path := "user://quick_save.scn"
		get_tree().change_scene_to(load(file_path))
		await get_tree().process_frame
		State._load_state(get_tree().current_scene.get_meta("STATE"))
		print("Quick loaded from: %s." % file_path)
		print("S", get_tree().get_first_node_in_group("sooty_stack").stack._stack)
