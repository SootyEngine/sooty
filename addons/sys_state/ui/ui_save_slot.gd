extends Control

var _tween: Tween
var _slot_info: Dictionary

func _ready() -> void:
#	focus_entered.connect(_focus_entered)
#	focus_exited.connect(_focus_exited)
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
	modulate = Color.LIGHT_GRAY

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if len(_slot_info):
			match e.button_index:
				MOUSE_BUTTON_LEFT:
					print("Select")
					owner._select_slot(get_index())

func set_info(info: Dictionary):
	_slot_info = info
	if info:
		$mask/preview.set_texture(info.preview)
		var r = DateTime.create_from_current().get_relation_string(info.date_time)
		$label.set_bbcode("%s [dim;i](%s)[]" % [r, info.dir_size])
	else:
		$mask/preview.set_texture(load("res://icon.png"))
		$label.set_bbcode("Empty")

func _mouse_entered():
	if not len(_slot_info):
		return
	if _tween:
		_tween.stop()
	_tween = get_tree().create_tween().set_parallel().bind_node(self)
	_tween.tween_property($mask/preview, "rect_scale", Vector2.ONE * 1.05, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property($mask/preview, "rect_rotation", deg2rad(1.0), 0.25)
	_tween.tween_property(self, "modulate", Color.WHITE, 0.25)

func _mouse_exited():
	if not len(_slot_info):
		return
	if _tween:
		_tween.stop()
	_tween = get_tree().create_tween().set_parallel().bind_node(self)
	_tween.tween_property($mask/preview, "rect_scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	_tween.tween_property($mask/preview, "rect_rotation", 0.0, 0.25)
	_tween.tween_property(self, "modulate", Color.LIGHT_GRAY, 0.25)
