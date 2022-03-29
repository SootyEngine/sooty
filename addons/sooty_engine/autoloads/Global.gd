@tool
extends Node

const VERSION := "0.1_alpha"

signal started()
signal ended()
signal message(type: String, payload: Variant)

var active_game := true#false

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

func call_group(group: String, fname: String, args := []):
	match len(args):
		0: return get_tree().call_group(group, fname)
		1: return get_tree().call_group(group, fname, args[0])
		2: return get_tree().call_group(group, fname, args[0], args[1])
		3: return get_tree().call_group(group, fname, args[0], args[1], args[2])
		4: return get_tree().call_group(group, fname, args[0], args[1], args[2], args[3])
		_: push_error("Not implemented.")
		
func call_group_flags(flags: int, group: String, fname: String, args := []):
	match len(args):
		0: return get_tree().call_group_flags(flags, group, fname)
		1: return get_tree().call_group_flags(flags, group, fname, args[0])
		2: return get_tree().call_group_flags(flags, group, fname, args[0], args[1])
		3: return get_tree().call_group_flags(flags, group, fname, args[0], args[1], args[2])
		4: return get_tree().call_group_flags(flags, group, fname, args[0], args[1], args[2], args[3])
		_: push_error("Not implemented.")

func _init() -> void:
	add_to_group("sa:sooty_version")

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	# TODO: Autosave.
	await Saver.temp_save()
	# TODO: Show quit screen with "Are you sure?" message.
	get_tree().quit()

func start():
	active_game = true
	started.emit()

func end():
	active_game = false
	ended.emit()

func sooty_version():
	return "[%s]%s[]" % [Color.TOMATO, VERSION]

func snap_screenshot():
	_screenshot = get_viewport().get_texture().get_image()
