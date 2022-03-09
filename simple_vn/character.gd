extends Node2D

@onready var anim_movement: AnimationPlayer = $movement
@onready var anim_color: AnimationPlayer = $color

func _init() -> void:
	add_to_group("sa:%s" % name)

const _anim_ARGS := ["", "", ""]
func anim(id: String, backwards: bool = false, speed: float = 1.0):
	prints("got", id, backwards, speed)
	for a in [anim_movement, anim_color]:
		if a.has_animation(id):
			if backwards:
				a.play_backwards(id)
			else:
				a.play(id, -1, speed)
	
#	get_tree().get_first_node_in_group("sooty_stack").stack.wait = true
#	add_to_group("sooty_waiting")
#	set_process(true)

#func _process(delta: float) -> void:
#	for a in [anim_movement, anim_color]:
#		if a.is_playing():
#			return
#
#	get_tree().get_first_node_in_group("sooty_stack").stack.wait = false
#	remove_from_group("sooty_waiting")
#	set_process(false)
