@tool
extends Resource
class_name UGroup

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
