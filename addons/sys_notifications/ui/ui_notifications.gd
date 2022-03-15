extends Node

@export var prefab: PackedScene
@export var wait := false
@export var queue := []
@export var time_delay := 2.0

func _ready() -> void:
	$Button.pressed.connect(_ping)
	Notify.notified.connect(_ping)

func _ping(msg := {}):
	queue.append(msg)
	_next()

func _next():
	if len(queue) and not wait:
		var n: Node = prefab.instantiate()
		n.tree_exited.connect(_next)
		$VBoxContainer.add_child(n)
		$VBoxContainer.move_child(n, 0)
		n.setup.call_deferred(queue.pop_front())
		
		wait = true
		get_tree().create_timer(time_delay).timeout.connect(_stop_waiting)

func _stop_waiting():
	wait = false
	_next()
