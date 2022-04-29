@tool
extends RefCounted
class_name UGroup

static func first_where(group: String, filter: Dictionary) -> Node:
	for node in get_all(group):
		var matches := true
		for k in filter:
			if not k in node or node[k] != filter[k]:
				matches = false
				break
		if matches:
			return node
	return null

static func first(group: String) -> Node:
	return Global.get_tree().get_first_node_in_group(group)

static func get_all(group: String) -> Array[Node]:
	return Global.get_tree().get_nodes_in_group(group)

# remove all nodes in a group
static func remove(group: String):
	for node in Global.get_tree().get_nodes_in_group(group):
		node.get_parent().remove_child(node)
		node.queue_free()

# find all groups
# go down the tree, starting from given node, and collect all distinct groups
static func get_all_from(from: Node = Global.get_tree().root) -> Array:
	var out := []
	UNode.dig(from, func(x: Node):
		for group in x.get_groups():
			if not group in out:
				out.append(group))
	return out

# dict where keys are the names of nodes in the group
static func get_dict(group: String) -> Dictionary:
	return UDict.map_on_property(Global.get_tree().get_nodes_in_group(group), "name")
