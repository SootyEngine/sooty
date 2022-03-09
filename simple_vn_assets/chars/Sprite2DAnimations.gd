@tool
extends Sprite2D
class_name Sprite2DAnimations

@export var tint := Color.WHITE
@export var unit := 64
@export var default_scale := Vector2.ONE
@export var current_zoom := 1.0:
	set = set_zoom

@export var current_noise := Vector2.ZERO:
	set = set_noise

@export var current_shake := Vector2.ZERO:
	set = set_shake

@export var current_squish := 0.0:
	set = set_squish

@export var current_shift := Vector2.ZERO:
	set = set_shift

@export var origin := Vector2(0.5, 1.0):
	set = set_origin

func _get_tool_buttons():
	return [fade_in, fade_out, noise,
	noise.bind(1, 1, {yscale=2.0}),
	blink,
	[blink, noise],
	shift,
	[fade_in, shift.bind(-1, 0, 0.5, true)],
	shift_in,
	from_left, from_right, from_top,
	
	zoom.bind(.9),
	zoom,
	zoom.bind(1.1),
	
	squash.bind(-1),
	squash.bind(1),
	squash,
	
	lean.bind(-1),
	lean,
	lean.bind(1),
	
	rotate.bind(-10),
	rotate,
	rotate.bind(10),
	
	laugh, sigh,
	
	shake_yes, shake_no,
	breath, pant, stop
]

var active: Tween

func fade_in():
	var t := _create()
	_add_color(t, Color.WHITE)

func fade_out():
	var t := _create()
	_add_color(t, Color.TRANSPARENT)

func from_left(dur := 0.5):
	var t := _create().set_parallel()
	modulate = Color.TRANSPARENT
	current_shift = Vector2(unit * 6, 0)
	_add_color(t, Color.WHITE, {ease=Tween.EASE_OUT})
	_add_shift(t, 0, 0, {ease=Tween.EASE_OUT, trans=Tween.TRANS_QUINT})

func from_right(dur := 0.5):
	var t := _create().set_parallel()
	modulate = Color.TRANSPARENT
	current_shift = Vector2(unit * -6, 0)
	_add_color(t, Color.WHITE, {ease=Tween.EASE_OUT})
	_add_shift(t, 0, 0, {ease=Tween.EASE_OUT, trans=Tween.TRANS_QUINT})

func from_top(dur := 0.5):
	var t := _create().set_parallel()
	modulate = Color.TRANSPARENT
	current_shift = Vector2(0, unit * -6)
	_add_color(t, Color.WHITE, {ease=Tween.EASE_OUT})
	_add_shift(t, 0, 0, {ease=Tween.EASE_OUT, trans=Tween.TRANS_BOUNCE})

func laugh():
	var t := _create()
	t.set_parallel()
	_add_shake(t, 0.5, 1.0, {ytimes=4.0, yscale=0.5})
	_add_rotate(t, -4.0)
	_add_squash(t, -1)
	_add_squash(t.chain())
	_add_rotate(t)

func _create(kwargs := {}) -> Tween:
	if active:
		active.kill()
	active = get_tree().create_tween()
	active.bind_node(self)
	if "loop" in kwargs:
		active.set_loops(kwargs.loop)
	return active

func sigh():
	var t := _create()
	_add_squash(t, -.2, 0.25, {trans="linear", ease="out"})
	_add_squash(t, 1.25, 2.0)

func shake_yes():
	var t := _create().set_parallel()
	_add_shake(t, 0.5, 1.0, {yscale=1.0, ytimes=3, xscale=0.0})
	_add_blink(t, Color.AQUAMARINE)

func shake_no():
	var t := _create().set_parallel()
	_add_shake(t, 0.5, 1.0, {yscale=0.0, xtimes=3, xscale=1.0})
	_add_blink(t, Color.TOMATO)

func breath():
	var t := _create()
	_add_squash(t, -0.1, 1.5, {trans=Tween.TRANS_SINE})
	_add_squash(t, 0.5, 1.5, {trans=Tween.TRANS_SINE})
	t.set_loops(5.0)

func pant(p := 1.0, dur := 0.5):
	var t := _create()
	_add_squash(t, -0.25 * p, dur, {ease=Tween.EASE_OUT})
	_add_squash(t, 0.25 * p, dur, {ease=Tween.EASE_OUT})
	t.set_loops(5)

func stop():
	if active:
		active.kill()

func _add_color(t: Tween, c: Variant = Color.WHITE, kwargs := {}):
	t.tween_property(self, "modulate", c, kwargs.get("time", 1.0))\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_LINEAR)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

func noise(power := 1.0, dur := 1.0, kwargs := {}):
	_add_noise(_create(), power, dur, kwargs)

func _add_noise(t: Tween, power := 1.0, dur := 1.0, kwargs := {}):
	return t.tween_method(_noise.bind(power, kwargs), 0.0, 1.0, dur)\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_LINEAR)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

func _noise(t: float, power: float, kwargs: Dictionary):
	t = 1.0 - absf(t - 0.5) * 2.0
	t *= t # smoothing.
	var n := URand.noise_animated_v2(position, kwargs.get("turb", 1.0))
	n.x *= kwargs.get("xscale", 1.0) as float
	n.y *= kwargs.get("yscale", 1.0) as float
	n *= kwargs.get("unit", unit) as float
	n *= t * power
	current_noise = n

func shake(power := 1.0, dur := 1.0, kwargs := {}):
	_add_shake(_create(), power, dur, kwargs)

func _add_shake(t: Tween, power := 1.0, dur := 1.0, kwargs := {}):
	return t.tween_method(_shake.bind(power, kwargs), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)

func _shake(t: float, power: float, kwargs: Dictionary):
	var sh := Vector2(
		sin(t * kwargs.get("xtimes", 2.0) * -TAU),
		sin(t * kwargs.get("ytimes", 2.0) * -TAU))
	sh *= power * unit
	sh.x *= kwargs.get("xscale", 1.0) as float
	sh.y *= kwargs.get("yscale", 0.0) as float
	current_shake = sh

func blink(color: Variant = Color.TOMATO, kwargs := {}):
	_add_blink(_create(), color, kwargs)

func _add_blink(t: Tween, color: Variant = Color.TOMATO, kwargs := {}):
	t.tween_method(_blink.bind(color, kwargs), 0.0, 1.0, kwargs.get("time", 1.0))

func _blink(t: float, color: Color, kwargs: Dictionary):
	modulate = tint.lerp(color, pingpong(t * kwargs.get("count", 1.0) * 2.0, 1.0))

func shift(x := 0.0, y := 0.0, kwargs := {}):
	_add_shift(_create(), x, y, kwargs)

func _add_shift(t: Tween, x := 0.0, y := 0.0, kwargs := {}):
	var v := Vector2(x, y) * (kwargs.get("unit", unit) as float)
	t.tween_property(self, "current_shift", v, kwargs.get("time", 1.0))\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_BACK)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

func shift_in(x := 0.0, y := 0.0, dur := 0.5, from_start := true, kwargs := {}):
	var t := _create()
	var v := Vector2(x, y) * (kwargs.get("unit", unit) as float)
	t.tween_property(self, "current_shift", Vector2.ZERO, dur)\
		.from(v if from_start else current_shift)\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_BACK)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

func zoom(to := 1.0, dur := 0.5, kwargs := {}):
	var t := _create()
	t.tween_method(set_zoom, current_zoom, to, dur)\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_BACK)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))
	return t
	
func squash(x := 0.0, dur := 0.5, kwargs := {}):
	_add_squash(_create(), x, dur, kwargs)

func _add_squash(t: Tween, x := 0.0, dur := 0.5, kwargs := {}):
	return t.tween_property(self, "current_squish", x * .05, dur)\
		.set_trans(UTween.find_trans(kwargs.get("trans", Tween.TRANS_BACK)))\
		.set_ease(UTween.find_ease(kwargs.get("ease", Tween.EASE_IN_OUT)))

func lean(l := 0.0, dur := 0.5):
	_add_lean(_create(), l, dur)

func _add_lean(t: Tween, l := 0.0, dur := 0.5):
	t.tween_property(self, "skew", l * .1, dur).set_trans(Tween.TRANS_BACK)

func rotate(x := 0.0, time := 0.5):
	_add_rotate(_create(), x, time)

func _add_rotate(t: Tween, x := 0.0, time := 0.5):
	t.tween_property(self, "rotation", deg2rad(x), time).set_trans(Tween.TRANS_BACK)

func set_shake(n: Vector2):
	current_shake = n
	_update_offset()

func set_noise(n: Vector2):
	current_noise = n
	_update_offset()

func set_shift(n: Vector2):
	current_shift = n
	_update_offset()

func set_zoom(z: float):
	current_zoom = z
	_update_scale()

func set_origin(o: Vector2):
	origin = o
	_update_offset()

func set_squish(x: float):
	current_squish = x
	_update_scale()
	_update_offset()

func _update_scale():
	var s := current_squish + 1.0
	scale = default_scale * Vector2(s, 1.0 / s) * current_zoom

func _update_offset():
	var s := texture.get_size()
	offset = -origin * s
	offset += current_noise
	offset += current_shake
	offset += current_shift
	if centered:
		offset += s * .5
