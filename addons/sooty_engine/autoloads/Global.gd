@tool
extends Node

const VERSION := "0.1_alpha"
var flags: Array[String] = [VERSION]

signal started()
signal ended()
signal added_to_group(node: Node, group: String)
signal removed_from_group(node: Node, group: String)
signal message(type: String, payload: Variant)

var active_game := true

func _init() -> void:
	add_to_group("@.version")
	add_to_group("@.msg")

func version() -> String:
	return VERSION

func msg(type: String, payload: Variant = null):
	message.emit(type, payload)

@onready var config := Config.new("res://config.cfg") # the main config settings file. TODO: add reload option in settings
var _screenshot: Image # a copy of the screen, for use in menus, or save system.

var window_width: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_width")

var window_height: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_height")

var window_size: Vector2:
	get: return Vector2(window_width, window_height)

var window_aspect: float:
	get: return float(window_width) / float(window_height)

var scene_id: String:
	get: return UFile.get_file_name(get_tree().current_scene.scene_file_path)

func notify(msg: Dictionary):
	message.emit("notification", msg)

func call_group(group: String, method: String, args := [], as_string_args := false) -> Variant:
	var out: Variant
	var nodes := get_tree().get_nodes_in_group(group)
	for node in nodes:
		var got = UObject.call_w_kwargs([node, method], args, as_string_args)
		if got != null:
			out = got
	if len(nodes) == 0:
		push_warning("No nodes in group '%s' to call '%s' on with %s." % [group, method, args])
	return out

func get_group_property(group: String, property: String) -> Variant:
	return get_tree().get_first_node_in_group(group)[property]

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	# TODO: Show quit screen with "Are you sure?" message.
	get_tree().quit()

func start():
	active_game = true
	started.emit()

func end():
	active_game = false
	ended.emit()

func snap_screenshot():
	_screenshot = get_viewport().get_texture().get_image()

# add to group and emit signal alerting everyone.
func add_node_to_group(node: Node, group: String):
	if not node.is_in_group(group):
		node.add_to_group(group)
		added_to_group.emit(node, group)

# remove from group and emit signal alerting everyone.
func remove_node_from_group(node: Node, group: String):
	if node.is_in_group(group):
		node.remove_from_group(group)
		removed_from_group.emit(node, group)
