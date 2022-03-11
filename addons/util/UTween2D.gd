@tool
extends Resource
class_name UTween2D

const DEFAULT_UNIT := 16.0
const DEFAULT_TIME := 1.0

static func add_noise(n: CanvasItem, t: Tween, power := 1.0, kwargs := {}):
	return t.tween_method(_noise.bind(n, power, kwargs), 0.0, 1.0, kwargs.get("time", DEFAULT_TIME))\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_LINEAR)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

static func add_shake(n: CanvasItem, t: Tween, power := 1.0, kwargs := {}):
	return t.tween_method(_shake.bind(n, power, kwargs), 0.0, 1.0, kwargs.get("time", DEFAULT_TIME))\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_LINEAR)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

static func _noise(t: float, n: CanvasItem, power: float, kwargs: Dictionary):
	t = 1.0 - absf(t - 0.5) * 2.0
	t *= t # smoothing.
	var noise := URand.noise_animated_v2(n.position, kwargs.get("turb", 1.0))
	noise.x *= kwargs.get("xscale", 1.0) as float
	noise.y *= kwargs.get("yscale", 1.0) as float
	noise *= kwargs.get("unit", DEFAULT_UNIT) as float
	noise *= t * power
	n.noise_offset = noise

static func _shake(n: CanvasItem, t: float, power: float, kwargs: Dictionary):
	var shake := Vector2(
		sin(t * kwargs.get("xtimes", 2.0) * -TAU),
		sin(t * kwargs.get("ytimes", 2.0) * -TAU))
	shake *= power * kwargs.get("unit", DEFAULT_UNIT)
	shake.x *= kwargs.get("xscale", 1.0) as float
	shake.y *= kwargs.get("yscale", 0.0) as float
	n.shake_offset = shake
