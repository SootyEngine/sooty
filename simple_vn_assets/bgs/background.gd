@tool
extends Sprite2D

func _get_tool_buttons():
	return [center, scale_to_window]

func center():
	position = Global.window_size * .5

func scale_to_window():
	var s := get_texture().get_size()
	var a := s.x / s.y
	scale = Global.window_size / get_texture().get_size()
	scale.y *= a
