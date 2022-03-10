extends Node2D

@onready var sprite: Sprite2DAnimations = $sprite

func _init() -> void:
	add_to_group("sa:anim")

func anim(char_id: String, action: String, args := []):
	prints("ANIM ", char_id, action, args)
	
	if char_id == name or char_id == "*":
		if sprite.has_method(action):
			sprite.callv(action, args)
		else:
			prints("No action ", action, "in", char_id)
