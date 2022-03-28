@tool
extends Control

func _ready() -> void:
	set_visible(false)
	set_process(false)

func start(file: FE_File):
	set_process(true)
	$label.set_text("File being moved...")

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() + Vector2(4, 4)
