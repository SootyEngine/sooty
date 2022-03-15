extends Control

@export var _bar: NodePath
@onready var bar: TextureProgressBar = get_node(_bar)
@export var _label: NodePath
@onready var label: RichTextLabel2 = get_node(_label)
@export var _icon: NodePath
@onready var icon: TextureRect = get_node(_icon)
@export var _progress: NodePath
@onready var progress: ProgressBar = get_node(_progress)

func setup(info: Dictionary):
	label.set_bbcode("[hide].[]")
	
	var time := 5.0
	
	# main animation
	var tw := get_tree().create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.5).from(0.0)
	tw.tween_property(self, "rect_position:x", 0.0, 0.5).from(120.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT).from_current()
	tw.chain().tween_property(bar, "value", 0.0, time).from(100.0)
	tw.chain().tween_property(self, "rect_position:x", 120.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT).from_current()
	tw.tween_property(self, "modulate:a", 0.0, 0.5).from_current()
	tw.chain().tween_callback(queue_free)
	
	# text animation
	tw = get_tree().create_tween()
	tw.tween_interval(0.25)
	var text: Array = UList.list(info.get("text", []))
	var t_time := (time / len(text)) * 0.5
	for i in len(text):
		# set text
		tw.tween_callback(label.set_bbcode.bind(text[i]))
		# fade in
		tw.tween_property(label, "modulate:a", 1.0, t_time*0.25).from(0.0)
		# wait
		tw.tween_interval(t_time*1.5)
		# fade out
		if i != len(text)-1:
			tw.tween_property(label, "modulate:a", 0.0, t_time*0.25)
	
	# progress bar animation
	if not "prog" in info:
		progress.visible = false
	else:
		tw = get_tree().create_tween()
		tw.tween_interval(0.25)
		tw.tween_property(progress, "value", info.prog * 100.0, 1.0).set_trans(Tween.TRANS_BACK)
