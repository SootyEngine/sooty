extends Node2D

@onready var pos: Vector2

func _ready() -> void:
	pos = global_position / get_parent().motion_scale

func _init():
	add_to_group("camera_target")
