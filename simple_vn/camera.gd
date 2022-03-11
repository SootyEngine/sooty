@tool
extends Camera2D

@onready var position_at_start: Vector2 = position
@onready var flow_manager: Node = get_tree().get_first_node_in_group("flow_manager")

@export var _zoom := 0.25
@export var zoom_offset := 0.0
@export var zoom_noise_scale := 1.0

@export var rotation_noise_scale := 1.0

@export var noise_scale := 0.0
@export var noise_aspect := Vector2(1.0, 0.25)
@export var noise_unit := 16.0
@export var noise_time_scale := 1.0
var noise_offset := Vector2.ZERO
var shake_offset := Vector2.ZERO

var position_offset := Vector2.ZERO

func _init() -> void:
	add_to_group("sa:camera")

func _get_tool_buttons():
	return [center]

func camera(action: String, args: Array = [], kwargs: Dictionary = {}):
	if has_method("__" + action):
		var t := get_tree().create_tween()
		var a := [t] + args + [kwargs]
		UObject.call_w_args(self, "__" + action, a)
		
		if kwargs.get("wait", false):
			if flow_manager.add_pauser(self):
				t.tween_callback(flow_manager.remove_pauser.bind(self))
	else:
		print("\tno action ", action)

func set_target(id: String):
	var target := UGroup.get_first_where("camera_target", {name=id})
	if target:
		position = target.pos - Global.window_size * .5

func _draw() -> void:
	if Engine.is_editor_hint():
		var s: Vector2 = Global.window_size
		var c := s / 2.0
		var t := s / 3.0
		
		var width := 8.0
		var hw = width / 2.0
		
		# outline
		draw_rect(Rect2(-c, s), Color.WHITE, false, width)
		# horizontal 3rd
		draw_line(Vector2(t.x-c.x, -c.y+hw), Vector2(t.x-c.x, c.y-hw), Color.WHITE, width)
		draw_line(Vector2(t.x*2-c.x, -c.y+hw), Vector2(t.x*2-c.x, c.y-hw), Color.WHITE, width)
		
		draw_line(Vector2(-c.x+hw, t.y-c.y), Vector2(c.x-hw, t.y-c.y), Color.WHITE, width)
		draw_line(Vector2(-c.x+hw, t.y*2-c.y), Vector2(c.x-hw, t.y*2-c.y), Color.WHITE, width)
		
		draw_circle(-position, 16.0, Color.WHITE)

var tween: Tween
func _get_tween():
	if tween:
		tween.stop()
	tween = get_tree().create_tween()
	return tween

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_left"):
		var t := _get_tween()
		t.tween_property(self, "position_offset:x", -64.0, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		print("create tween")
	
	if Input.is_action_just_pressed("ui_right"):
		var t := _get_tween()
		t.tween_property(self, "position_offset:x", 64.0, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		print("create tween")
	
	if Input.is_action_just_pressed("ui_down"):
		var t := _get_tween()
		t.tween_property(self, "position_offset:x", 0.0, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		print("create tween")
	
	if Input.is_action_just_pressed("ui_up"):
		var t := _get_tween()
		t.tween_property(self, "zoom_offset", 0.0 if zoom_offset != 0.0 else randf_range(-.5, .5), 1.0).set_trans(Tween.TRANS_BACK)
		print("create tween")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	noise_offset = URand.fbm_animated_v2(position, 0.0125 * noise_time_scale)
	noise_offset *= noise_unit
	noise_offset *= noise_aspect
	noise_offset *= noise_scale
	
	get_parent().rotation = URand.noise_animated(-position.x, 0.1) * 0.0025 * rotation_noise_scale
	zoom = Vector2.ONE * (1.0 + zoom_offset + URand.noise_animated(-position.y, 0.1) * .00125 * zoom_noise_scale)
	offset = noise_offset + shake_offset + position_offset
	offset += ((get_global_mouse_position() / Global.window_size) - Vector2(.5, .5)) * Vector2(1, 0.125) * 32.0
	
func center():
	if anchor_mode == ANCHOR_MODE_FIXED_TOP_LEFT:
		position = Vector2.ZERO
	else:
		position = Global.window_size * .5

func __zoom(t: Tween, amount: float = 1.0, time: float = 0.5):
	t.tween_method(set_zoom, zoom, Vector2.ONE * (1.0 / amount), time).set_trans(Tween.TRANS_BACK)

func __tilt(t: Tween, amount: float = 0.0, time: float = 0.5):
	t.tween_method(set_rotation, rotation, deg2rad(amount), time).set_trans(Tween.TRANS_BACK)

func __shake(t: Tween, amount: float = 1.0, time: float = 1.0, kwargs: Dictionary = {}):
	t.tween_method(set_shake.bind(amount, kwargs), 0.0, 1.0, time)

func __move(t: Tween, x: float = 0.0, y: float = 0.0, time: float = 0.5):
	t.tween_method(set_position, position, position + Vector2(x, y), time).set_trans(Tween.TRANS_BACK)
	
func __move_back(t: Tween, time: float = 0.5):
	t.tween_method(set_position, position, position_at_start, time).set_trans(Tween.TRANS_BACK)

func set_shake(t: float, amount: float, kwargs: Dictionary):
	# 0-1 -> 0-1-0
	t = 1.0 - absf(t - 0.5) * 2.0
	t *= t # smoothing
	var n := URand.noise_animated_v2(position) # get noise
	n.y *= .33 # shrink horizontal noise
	shake_offset = n * t * kwargs.get("pixels", 32.0) * amount
