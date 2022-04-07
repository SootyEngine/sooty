extends RefCounted
class_name Data

func _init(d := {}):
	UObject.set_state(self, d)
	_post_init.call_deferred()

func _post_init():
	pass

func _to_string() -> String:
	return UObject._to_string_nice(self)

func duplicate() -> Object:
	return UObject.duplicate_object(self)

# used for formatting.
func get_string(id := "") -> String:
	return ""
