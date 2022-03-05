@tool
extends Node

#var _d := {}

func get_states() -> Array:
	return [State, get_tree().current_scene]
