extends Node
class_name Fader

static func create(callback: Variant, kwargs := {}):
	var node = load("res://addons/simple_vn/fader/fader.tscn").instantiate()
	Global.add_child(node)
	node.setup(callback, kwargs)

func setup(callback: Variant, kwargs: Dictionary = {}):
	var t := get_tree().create_tween()
	$backing.modulate = kwargs.get("color", Color.BLACK)
	match kwargs.get("anim", "in_out"):
		"in":
			$backing.modulate.a = 1.0
			t.tween_property($backing, "modulate:a", 0.0, kwargs.get("time", 1.0))
			if callback is Callable:
				t.tween_callback(callback)
		"in_out":
			$backing.modulate.a = 0.0
			t.tween_property($backing, "modulate:a", 1.0, kwargs.get("time", 1.0))
			if callback is Callable:
				t.tween_callback(callback)
			t.tween_property($backing, "modulate:a", 0.0, kwargs.get("time", 1.0))
	t.tween_callback(queue_free)
	if "done" in kwargs:
		t.tween_callback(kwargs.done)
