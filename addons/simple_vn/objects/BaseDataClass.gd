extends Resource
class_name BaseDataClass

func _init(d := {}):
	UObject.patch(self, d, true)
	_post_init.call_deferred()

func _post_init():
	pass

func _to_string() -> String:
	var c := get_class()
	var s: Script = get_script()
	for line in s.source_code.split("\n", false, 2):
		if line.begins_with("class_name"):
			c = line.split("class_name", true, 1)[1].strip_edges()
			break
	var p = State._get_objects_property(self)
	return "[%s:%s]" % [c, p]
