extends "res://addons/sooty_engine/autoloads/ResManager.gd"
class_name UIManager

var active := {}

func _ready() -> void:
	super._ready()
	var _sooty := Global.get_node("/root/Sooty")
	_sooty.actions.connect_as_node(self, "UI")
	_sooty.actions.connect_methods([is_showing_ui, show_ui, toggle_ui, hide_ui])

func is_showing_ui(id: String) -> bool:
	return id in active and is_instance_valid(active[id]) and active[id].is_inside_tree()

func toggle_ui(id: String):
	if is_showing_ui(id):
		hide_ui(id)
	else:
		show_ui(id)

func hide_ui(id: String):
	if id in active and active[id].is_inside_tree():
		active[id].get_parent().remove_child(active[id])

func show_ui(id: String, parent: Node = Global) -> Node:
	var path := find(id)
	if path:
		# has valid instance?
		if id in active and is_instance_valid(active[id]):
			if not active[id].is_inside_tree():
				parent.add_child(active[id])
			return active[id]
		else:
			print("Creating ui ", id)
			var out: Node = load(path).instantiate()
			out.name = id
			active[id] = out
			parent.add_child(out)
			return out
	else:
		return null

func _get_res_dir() -> String:
	return "scenes_ui"

func _get_res_extensions() -> Array:
	return [".scn", ".tscn"]
