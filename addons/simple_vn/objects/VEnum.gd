extends BaseDataClass
class_name VEnum

@export var text := {}
@export var states: Array[String] = []
@export var on_changed := ""
@export var on_state := {}
@export var value := "":
	set(v):
		if value != v:
			value = v
			if value in on_state and len(on_state[value]):
				_eval(on_state[value])
			if len(on_changed):
				_eval(on_changed)

func _operator_get():
	return value

func _operator_set(v):
	if v is String:
		value = v

func to_string() -> String:
	return text.get(value, "NO_STATE:%s" % value)
