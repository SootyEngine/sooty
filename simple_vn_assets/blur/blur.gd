@tool
extends Control

@export_range(0.0, 1.0) var amount := 0.0:
	set = set_amount

@export var power := 4.0:
	set = set_power

@export var default_duration := 2.0

func _init() -> void:
	add_to_group("sa:blur")
	add_to_group("sa:unblur")
	amount = 0.0
	visible = false

func _get_tool_buttons():
	return [blur, unblur]

func unblur(kwargs := {}):
	blur(0.0, kwargs)

func blur(to := 1.0, kwargs := {}):
	var t := get_tree().create_tween()
	t.tween_method(set_amount, amount, to, kwargs.get("time", default_duration))\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	if "power" in kwargs:
		t.tween_method(set_power, power, kwargs.power, kwargs.get("time", default_duration))

func set_amount(x: float):
	amount = x
	(material as ShaderMaterial).set_shader_param("amount", x)
	visible = amount >= 0.0
	
func set_power(x: float):
	power = x
	(material as ShaderMaterial).set_shader_param("power", x)
