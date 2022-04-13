@tool
extends RefCounted
class_name UNode

static func get_all_groups(from: Node = Global.get_tree().root) -> Array:
	var out := []
	dig(from, func(x: Node):
		for group in x.get_groups():
			if not group in out:
				out.append(group))
	return out

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
