@tool
extends Node

signal message(type: String, payload: Variant)

@onready var config := Config.new("res://config.cfg")

var window_width: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_width")

var window_height: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_height")

var window_size: Vector2:
	get: return Vector2(window_width, window_height)

var window_aspect: float:
	get: return float(window_width) / float(window_height)

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)

func _get(property: StringName):
	ProjectSettings

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
	
	if Input.is_action_just_pressed("reload_scene"):
		get_tree().reload_current_scene()
