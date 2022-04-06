extends Resource
class_name BaseDataClass

func _init(d := {}):
	UObject.set_state(self, d)
	_post_init.call_deferred()

func _post_init():
	pass

func _to_string() -> String:
	return UObject._to_string_nice(self)
