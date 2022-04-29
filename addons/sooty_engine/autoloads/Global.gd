@tool
extends Node

var screenshot: Image # a copy of the screen, for use in menus, or save system.
var _queued_solo_signals := {}

var window_width: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_width")

var window_height: int:
	get: return ProjectSettings.get_setting("display/window/size/viewport_height")

var window_size: Vector2:
	get: return Vector2(window_width, window_height)

var window_aspect: float:
	get: return float(window_width) / float(window_height)

func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 9223372036854775807
	
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

# queue a solo signal that will only fire once per tick
func queue_solo_signal(sig: Signal, args := []):
	_queued_solo_signals[sig] = args

func _physics_process(_delta: float) -> void:
	if _queued_solo_signals:
		for sig in _queued_solo_signals:
			var args: Array = _queued_solo_signals[sig]
			match len(args):
				0: sig.emit()
				1: sig.emit(args[0])
				2: sig.emit(args[1], args[2])
				3: sig.emit(args[1], args[2], args[3])
				4: sig.emit(args[1], args[2], args[3], args[4])
				5: sig.emit(args[1], args[2], args[3], args[4], args[5])
				_: push_error("Not implemented.")
		_queued_solo_signals.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	# TODO: Show quit screen with "Are you sure?" message.
	get_tree().quit()

func snap_screenshot():
	screenshot = get_viewport().get_texture().get_image()
