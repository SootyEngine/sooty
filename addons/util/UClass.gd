@tool
extends RefCounted
class_name UClass

# returns either an int type, or a String class_name
static func get_type_or_class(thing: Variant) -> Variant:
	if thing is Object:
		return get_class_name(thing)
	else:
		return typeof(thing)

# does a custom class exist?
static func exists(classname: String) -> bool:
	# the icons dictionary should be faster than iterating the class array.
	return classname in ProjectSettings.get_setting("_global_script_class_icons")

# create a custom built in object by class_name
static func create(classname: String, args := []) -> Variant:
	var obj = get_class_from_name(classname)
	if obj == null:
		UString.push_error_similar("No class_name '%s'." % classname, classname, get_all_class_names())
	else:
		match len(args):
			0: return obj.new()
			1: return obj.new(args[0])
			2: return obj.new(args[0], args[1])
			3: return obj.new(args[0], args[1], args[2])
			4: return obj.new(args[0], args[1], args[2], args[3])
			5: return obj.new(args[0], args[1], args[2], args[3], args[4])
			_: push_error("Not implemented.")
	return null

static func get_all_class_names() -> Array[String]:
	# should be faster than _global_script_classes
	return ProjectSettings.get_setting("_global_script_class_icons").keys()

static func get_class_from_name(classname: String) -> Variant:
	# TODO: cache this?
	for item in ProjectSettings.get_setting("_global_script_classes"):
		if item["class"] == classname:
			return load(item.path)
	return null

# try to find the icon for this class
static func get_icon(classname: String, default: Texture = null) -> Texture:
	var icons: Dictionary = ProjectSettings.get_setting("_global_script_class_icons")
	if classname in icons and icons[classname]:
		return load(icons[classname])
	return default

# forcibly pull the class_name from the script XD
# cache it inside the script's meta data
static func get_class_name(obj: Variant) -> String:
	var s: Script = obj if obj is Script else obj.get_script()
	if s.has_meta("class_name"):
#		print("Got from cache: %s." % s.get_meta("class_name"))
		return s.get_meta("class_name")
	
	# method 1) use the resource_path
	var classname := s.resource_path.get_file().split(".", true, 1)[0]
	s.set_meta("class_name", classname)
	return classname
	
	# method 2) go throug the actual source code
	var out = obj.get_class()
	for line in s.source_code.split("\n"):
		if line.begins_with("class_name "):
			line = line.trim_prefix("class_name ")
			if "," in line:
				line = line.split(",", true, 1)[0]
			line = line.strip_edges()
			s.set_meta("class_name", line)
			return line
	return out

# _to_string, but it pulls the real class_name
static func _to_string2(obj: Object) -> String:
	var classname = get_class_name(obj)
	if obj.has_method("get_id"):
		return "[%s:%s:%s]" % [classname, obj.get_id(), obj.get_instance_id()]
	else:
		return "[%s:%s]" % [classname, obj.get_instance_id()]
