@tool
extends RefCounted
class_name UGroup

# find all groups
# go down the tree, starting from given node, and collect all distinct groups
static func get_all(from: Node = Global.get_tree().root) -> Array:
#	print("GET ALL GROUPS ", from)
	var out := []
	UNode.dig(from, func(x: Node):
#		print("G", x, x.get_groups())
		for group in x.get_groups():
			if not group in out:
				out.append(group))
	return out

# dict where keys are the names of nodes in the group
static func get_dict(group: String) -> Dictionary:
	var out := {}
	for node in Global.get_tree().get_nodes_in_group(group):
		out[node.name] = node
	return out

static func get_first_where(group: String, filter: Dictionary) -> Node:
	for node in Global.get_tree().get_nodes_in_group(group):
		if _filter(node, filter):
			return node
	return null

static func get_where(group: String, filter: Dictionary) -> Array:
	return Global.get_tree().get_nodes_in_group(group).filter(_filter.bind(filter))

static func _filter(node: Node, filter: Dictionary) -> bool:
	for k in filter:
		if not k in node or node[k] != filter[k]:
			return false
	return true

