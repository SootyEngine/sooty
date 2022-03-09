@tool
extends Control

@export_range(0.0, 1.0) var amount := 0.0:
	set = set_amount

@export var power := 4.0:
	set = set_power

func _init() -> void:
	add_to_group("sa:blur")

func _get_tool_buttons():
	return ["blur_in", "blur_out"]

func blur_in():
	blur(1.0)

func blur_out():
	blur()

func blur(to := 0.0, time := 1.0, kwargs := {}):
	var t := get_tree().create_tween()
	t.tween_method(set_amount, amount, to, time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if "power" in kwargs:
		t.tween_method(set_power, power, kwargs.power, time)

func set_amount(x: float):
	amount = x
	(material as ShaderMaterial).set_shader_param("amount", x)
	
func set_power(x: float):
	power = x
	(material as ShaderMaterial).set_shader_param("power", x)
