extends Camera2D

@onready var position_at_start: Vector2 = position

func _init() -> void:
	add_to_group("sa:camera")

const _camera_ARGS := ["", "args"]
func camera(action: String, args: Array = []):
	if has_method("_" + action):
		UObject.call_w_args(self, "_" + action, args)

func _zoom(amount: float = 0.0, time: float = 0.5):
	var t := get_tree().create_tween()
	t.tween_method(set_zoom, zoom, Vector2.ONE * amount, time).set_trans(Tween.TRANS_BACK)

func _tilt(amount: float = 0.0, time: float = 0.5):
	var t := get_tree().create_tween()
	t.tween_method(set_rotation, rotation, deg2rad(amount), time).set_trans(Tween.TRANS_BACK)

func _shake(amount: float = 1.0, time: float = 1.0, kwargs: Dictionary = {pixels=32.0}):
	var t := get_tree().create_tween()
	t.tween_method(set_shake.bind(amount, kwargs), 0.0, 1.0, time)
	if kwargs.get("wait", false):
		var n := get_tree().get_first_node_in_group("flow_manager")
		n.add_pauser(self)
		t.tween_callback(n.remove_pauser.bind(self))

func _move(x: float = 0.0, y: float = 0.0, time: float = 0.5, kwargs: Dictionary = {}):
	var t := get_tree().create_tween()
	t.tween_method(set_position, position, position + Vector2(x, y), time).set_trans(Tween.TRANS_BACK)

func _move_back(time: float = 0.5):
	var t := get_tree().create_tween()
	t.tween_method(set_position, position, position_at_start, time).set_trans(Tween.TRANS_BACK)

func set_shake(t: float, amount: float, kwargs: Dictionary):
	# 0-1 -> 0-1-0
	t = 1.0 - absf(t - 0.5) * 2.0
	t *= t # smoothing
	var n := URand.noise_animated_v2(position) # get noise
	n.y *= .33 # shrink horizontal noise
	offset = n * t * kwargs.get("pixels", 32.0) * amount
