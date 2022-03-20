extends CanvasLayer

@onready var debug_menu = $debug_menu

func _ready() -> void:
	visible = false
	remove_child(debug_menu)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		if debug_menu.is_inside_tree():
			visible = false
			remove_child(debug_menu)
		else:
			visible = true
			add_child(debug_menu)
#		get_tree().paused = visible
