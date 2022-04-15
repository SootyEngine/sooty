@tool
extends RefCounted
class_name Data, "res://addons/sooty_engine/icons/data.png"
func _get_class():
	return "Data"

static func _str_to_instance(id: String, type: String):
	var manager_class := type + "Manager"
	var manager = UClass.get_class_script(manager_class)
	return manager.get(id)

func _init(d := {}):
	UObject.set_state(self, d)
	_post_init.call_deferred()

func _post_init():
	pass

func _to_string() -> String:
	return UClass._to_string2(self)

func get_manager():
	return DataManager.get_manager(_get_class())

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
