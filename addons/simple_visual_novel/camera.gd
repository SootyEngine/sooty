extends Camera2D

@onready var position_at_start: Vector2 = position
@onready var flow_manager: Node = get_tree().get_first_node_in_group("flow_manager")

@export var zoom_scale: float = 0.25

func _init() -> void:
	add_to_group("sa:camera")

#func _ready():
#	flow_manager.stack.tick_started.connect(_tick_started)
#	flow_manager.stack.tick_finished.connect(_tick_finished)
#
#func _tick_started():
#	print("TICK STARTED")
#
#func _tick_finished():
#	print("TICK ENDED")

func camera(action: String, args: Array = [], kwargs: Dictionary = {}):
	if has_method("_" + action):
		var t := get_tree().create_tween()
		var a := [t] + args + [kwargs]
		UObject.call_w_args(self, "_" + action, a)
		
		if kwargs.get("wait", false):
			if flow_manager.add_pauser(self):
				t.tween_callback(flow_manager.remove_pauser.bind(self))
	else:
		print("\tno action ", action)

func _zoom(t: Tween, amount: float = 1.0, time: float = 0.5):
	t.tween_method(set_zoom, zoom, Vector2.ONE * (1.0 / amount), time).set_trans(Tween.TRANS_BACK)

func _tilt(t: Tween, amount: float = 0.0, time: float = 0.5):
	t.tween_method(set_rotation, rotation, deg2rad(amount), time).set_trans(Tween.TRANS_BACK)

func _shake(t: Tween, amount: float = 1.0, time: float = 1.0, kwargs: Dictionary = {}):
	t.tween_method(set_shake.bind(amount, kwargs), 0.0, 1.0, time)

func _move(t: Tween, x: float = 0.0, y: float = 0.0, time: float = 0.5):
	t.tween_method(set_position, position, position + Vector2(x, y), time).set_trans(Tween.TRANS_BACK)
	
func _move_back(t: Tween, time: float = 0.5):
	t.tween_method(set_position, position, position_at_start, time).set_trans(Tween.TRANS_BACK)

func set_shake(t: float, amount: float, kwargs: Dictionary):
	# 0-1 -> 0-1-0
	t = 1.0 - absf(t - 0.5) * 2.0
	t *= t # smoothing
	var n := URand.noise_animated_v2(position) # get noise
	n.y *= .33 # shrink horizontal noise
	offset = n * t * kwargs.get("pixels", 32.0) * amount
