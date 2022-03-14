extends Node

func _ready() -> void:
	$Button.pressed.connect(_pressed)

func _pressed():
	get_tree().change_scene("res://addons/simple_vn/dialogue_runner.tscn")
