@tool
extends RefCounted
class_name Data

func _init(d := {}):
	UObject.set_state(self, d)
	_post_init.call_deferred()

func _post_init():
	pass

func _to_string() -> String:
	return UClass._to_string2(self)

func get_manager():
	return _get_manager(get_script())

func get_id() -> String:
	var manager = get_manager()
	if manager:
		return manager._get_id(self)
	return "NO_MANAGER"

func duplicate() -> Object:
	var classname := UClass.get_class_name(self)
	var output = UClass.create(classname)
	UObject.set_state(output, UObject.get_state(self))
	return output

static func _get_manager(object: Object):
	var classname := UClass.get_class_name(object)
	if classname in Global.meta:
		var instance_id: int = Global.meta[classname]
		return instance_from_id(instance_id)
	return null
