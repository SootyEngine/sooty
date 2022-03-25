extends Control

var _tween: Tween
var _slot_info: Dictionary

@export var _preview: NodePath
@export var _label_caption: NodePath
@export var _label_info: NodePath
@export var _caption_container: NodePath
@onready var preview: TextureRect = get_node(_preview)
@onready var label_caption: RichTextLabel2 = get_node(_label_caption)
@onready var label_info: RichTextLabel2 = get_node(_label_info)
@onready var caption_container: Control = get_node(_caption_container)

func _ready() -> void:
	gui_input.connect(_gui_input)
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
	preview.scale = Vector2.ONE * 0.8
	modulate = Color.LIGHT_GRAY

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and get_global_rect().has_point(get_global_mouse_position()):
		match e.button_index:
			MOUSE_BUTTON_LEFT:
				owner._select_slot(get_index())

func set_info(info: Dictionary):
	_slot_info = info
	if info:
		preview.set_texture(info.preview)
		preview.pivot_offset = info.preview.get_size() * .5
		var r = DateTime.create_from_current().get_relation_string(info.date_time)
		label_info.set_bbcode(r)
		label_info.hint_tooltip = info.dir_size
		if "caption" in info:
			label_caption.set_bbcode(info.caption)
	else:
		preview.set_texture(load("res://icon.png"))
		label_info.set_bbcode("Empty")
		label_info.hint_tooltip = ""
		label_caption.clear()

func _mouse_entered():
	if not len(_slot_info):
		return
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween().set_parallel().bind_node(self)
	_tween.tween_property(preview, "scale", Vector2.ONE * 0.85, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(preview, "rotation", deg2rad(1.0), 0.25)
	_tween.tween_property(label_caption, "modulate:a", 1.0, 0.25)
	_tween.tween_property(caption_container, "position:y", -4.0, 0.25)
	_tween.tween_property(self, "modulate:v", 1.0, 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN_OUT)

func _mouse_exited():
	if not len(_slot_info):
		return
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween().set_parallel().bind_node(self)
	_tween.tween_property(preview, "scale", Vector2.ONE * 0.8, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	_tween.tween_property(preview, "rotation", 0.0, 0.25)
	_tween.tween_property(label_caption, "modulate:a", 0.5, 0.25)
	_tween.tween_property(caption_container, "position:y", 0.0, 0.25)
	_tween.tween_property(self, "modulate:v", 0.8, 0.25)
