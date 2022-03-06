extends Node

@export var prefab: PackedScene
@export var wait: bool = false
@export var queue: Array = []

func _ready() -> void:
	$Button.pressed.connect(notify)

var index := 0
func notify(msg: Dictionary = {text="New Notification"}):
	msg.text += str(index)
	index += 1
	queue.append(msg)
	
	if not wait or not $VBoxContainer.get_child_count():
		_next()

func _next():
	if len(queue):
		var n: Node = prefab.instantiate()
		n.tree_exited.connect(_next)
		$VBoxContainer.add_child(n)
		$VBoxContainer.move_child(n, 0)
		n.setup(queue.pop_front())
