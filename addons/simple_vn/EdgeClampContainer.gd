@tool
extends Container

enum { TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTER, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT }

@export_enum(TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTER, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT) var edge: int = BOTTOM:
	set(e):
		edge = e
		_resized()

@export var margin := 0.0:
	set(m):
		margin = m
		_resized()

func _ready() -> void:
	resized.connect(_resized)

func _resized():
	
	match edge:
		BOTTOM:
			rect_size.y = 0.0
			hide()
			show()
			var vp := get_viewport_rect()
			rect_position.y = vp.size.y - rect_size.y - margin
