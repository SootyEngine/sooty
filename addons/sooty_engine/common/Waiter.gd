extends Node
class_name Waiter
# A node that waits on things before it can continue.

signal waiting_list_changed()

@export var _waiting_for := [] # objects that want the flow to _break

func is_waiting() -> bool:
	return len(_waiting_for) > 0

func wait(waiter: Object):
	if not waiter in _waiting_for:
		_waiting_for.append(waiter)
		waiting_list_changed.emit()

func unwait(waiter: Object):
	if waiter in _waiting_for:
		_waiting_for.erase(waiter)
		waiting_list_changed.emit()

func clear_waiting_list():
	_waiting_for.clear()
	waiting_list_changed.emit()

func get_waiting_paths() -> Array:
	return _waiting_for.map(func(node: Node):
		return node.get_path()) 
