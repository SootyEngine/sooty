@tool
extends RefCounted
class_name UNode

static func dig(node: Node, call: Callable):
	call.call(node)
	for child in node.get_children():
		dig(child, call)

static func dig_path(node: Node, call: Callable, path := []):
	call.call(node, path)
	path.push_back(node)
	for child in node.get_children():
		dig_path(child, call, path)
	path.pop_back()

static func remove_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
