extends BaseDataClass
class_name VBool

@export var text_true := ""
@export var text_false := ""
@export var on_changed := "" # called 
@export var on_true := ""
@export var on_false := ""
@export var value := false:
	set(v):
		if value != v:
			value = v
			if value and len(on_true):
				StringAction.do(on_true)
			if not value and len(on_false):
				StringAction.do(on_false)
			if len(on_changed):
				StringAction.do(on_changed)
			print("Toggled")

func _operator_get():
	return value

func _operator_set(v):
	if v is bool:
		value = v

func to_string() -> String:
	return text_true if value else text_false
