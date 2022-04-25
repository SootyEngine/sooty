@tool
extends RefCounted
class_name Data, "res://addons/sooty_engine/icons/data.png"
func get_class():
	return "Data"

signal changed()

func _init(d := {}):
	UObject.set_state(self, d)
	_post_init.call_deferred()

func signal_changed():
	Global.queue_solo_signal(changed)

func _post_init():
	pass

func _to_string() -> String:
	return UClass._to_string2(self)

func get_database() -> Database:
	return Sooty.databases.get_database(UClass.get_class_name(self))

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

func get_icon_path() -> String:
	return "res://gfx/icons"

func has_icon() -> bool:
	return UFile.exists("%s/%s.png" % [get_icon_path(), get_id()])

func get_icon() -> Texture:
	var path := "%s/%s.png" % [get_icon_path(), get_id()]
	if UFile.exists(path):
		return load(path)
	else:
		return load("res://icons.png")

# for use with the dialogue system
# you may want a stylized form, or a form based on language
func get_string(value: Variant, for_what := "") -> String:
	return "<<%s:%s:%s>>" % [get_id(), value, for_what]
