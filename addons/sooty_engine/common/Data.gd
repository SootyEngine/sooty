@tool
extends RefCounted
class_name Data, "res://addons/sooty_engine/icons/data.png"
func get_class():
	return "Data"

static func _str_to_instance(id: String, type: String):
	var database_class := type + "Database"
	var database = UClass.get_class_script(database_class)
	return database.get(id)

func _init(d := {}):
	UObject.set_state(self, d)
	_post_init.call_deferred()

func _post_init():
	pass

func _to_string() -> String:
	return UClass._to_string2(self)

func get_database():
	return Database.get_database(UClass.get_class_name(self))

func get_id() -> String:
	var database = get_database()
	if database:
		return database._get_id(self)
	return "NO_DATABASE"

func duplicate() -> Object:
	var classname := UClass.get_class_name(self)
	var output = UClass.create(classname)
	UObject.set_state(output, UObject.get_state(self))
	return output
