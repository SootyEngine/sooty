@tool
extends Resource
class_name UObject

const GLOBAL_SCOPE_METHODS := [
	"Color", "Vector2", "Vector2i", "Vector3", "Vector3i",
	"abs", "absf", "absi",
	"acos", "asin", "atan", "atan2",
	"bytes2var", "bytes2var_with_objects",
	"ceil", "clamp", "clampf", "clampi",
	"cos", "cosh",
	"cubic_interpolate",
	"db2linear",
	"deg2rad",
	"ease",
	"error_string",
	"exp",
	"floor",
	"fmod", "fposmod",
	"hash",
	"instance_from_id",
	"inverse_lerp",
	"is_equal_approx",
	"is_inf",
	"is_instance_id_valid",
	"is_instance_valid",
	"is_nan",
	"is_zero_approx",
	"lerp", "lerp_angle",
	"linear2db",
	"log",
	"max", "maxf", "maxi", "min", "minf", "mini",
	"move_toward",
	"nearest_po2",
	"pingpong",
	"posmod",
	"pow",
	"print", "print_verbose", "printerr", "printraw", "prints", "printt",
	"push_error", "push_warning",
	"rad2deg",
	"rand_from_seed", "randf", "randf_range", "randfn", "randi", "randi_range", "randomize",
	"range_lerp",
	"rid_allocate_id", "rid_from_int64",
	"round",
	"seed",
	"sign", "signf", "signi",
	"sin", "sinh",
	"smoothstep",
	"snapped",
	"sqrt",
	"step_decimals",
	"str", "str2var",
	"tan", "tanh",
	"typeof",
	"var2bytes", "var2bytes_with_objects",
	"weakref",
	"wrapf", "wrapi"
]

static func get_class_name(o: Object) -> String:
	return o.get_script().resource_path.get_file().split(".", true, 1)[0]

static func duplicate_object(input: Object) -> Object:
	var classname := get_class_name(input)
	var output = create(classname)
	set_state(output, get_state(input))
	return output

# looks for an object of given type
# call(player, HealthInfo) would look for "var health:HealthInfo" and return a reference to it.
static func get_first_property_of_object_type(target: Object, object_type: Variant):
	for k in get_state_properties(target):
		if target[k] is object_type:
			return target[k]
	return null

# get a serializable state. (can be Color and Vector2, but not Objects.)
static func get_state(target: Variant) -> Variant:
	if target is Object and target.has_method("_get_state"):
		return target._get_state()
	elif target is Array:
		var out = []
		for item in target:
			if typeof(item) in [TYPE_OBJECT, TYPE_DICTIONARY, TYPE_ARRAY]:
				out.append(get_state(item))
			else:
				out.append(item)
		return out
	else:
		var out := {}
		for k in get_state_properties(target):
			match typeof(target[k]):
				TYPE_OBJECT, TYPE_DICTIONARY, TYPE_ARRAY: out[k] = get_state(target[k])
				_: out[k] = target[k]
		return out

# set a serializable state.
static func set_state(target: Variant, state: Variant):
	if target is Object and target.has_method("_set_state"):
		target._set_state(state)
	elif target is Array:
		for i in len(state):
			set_state(target[i], state[i])
	elif state is Dictionary:
		for k in state:
			if k in target:
				match typeof(target[k]):
					TYPE_OBJECT, TYPE_DICTIONARY, TYPE_ARRAY: set_state(target[k], state[k])
					_: target[k] = state[k]
			else:
				push_error("No property '%s' in %s." % [k, target])
	else:
		assert(false)

# get list of script variables not starting in a _
static func get_state_properties(target: Variant) -> Array:
	match typeof(target):
		TYPE_OBJECT:
			if target.has_method("_get_state_properties"):
				return target._get_state_properties()
			else:
				return _get_state_properties(target)
		TYPE_DICTIONARY:
			return target.keys()
		_:
			return []

static func _get_state_properties(target: Object) -> Array:
	return target.get_property_list()\
		.filter(func(x): return x.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and x.name[0] != "_")\
		.map(func(x): return x.name)

static func get_operator_value(v):
	if v is Object:
		if v.has_method("_operator_get"):
			return v._operator_get()
	return v

static func callablev(c: Callable, args: Array) -> Variant:
	match len(args):
		0: return c.call()
		1: return c.call(args[0])
		2: return c.call(args[0], args[1])
		3: return c.call(args[0], args[1], args[2])
		4: return c.call(args[0], args[1], args[2], args[3])
		5: return c.call(args[0], args[1], args[2], args[3], args[4])
		6: return c.call(args[0], args[1], args[2], args[3], args[4], args[5])
		_:
			push_error("NOT IMPLEMENTED.")
			return null

# Properly divides an array as arguments for a function. Like python.
static func call_w_args(target: Object, method: String, in_args: Array = []) -> Variant:
	var obj = target
	
	if "." in method:
		var parts := method.split(".")
		for i in len(parts)-1:
			if parts[i] in obj:
				obj = obj[parts[i]]
			else:
				push_error("No method '%s(%s)' in %s." % [method, in_args, target])
		method = parts[-1]
	
	if not obj.has_method(method):
		push_error("No method '%s(%s)' in %s." % [method, in_args, obj])
		return
	
	var arg_info = get_method_arg_info(obj, method)
	
	# no args mean it was probably not a script function but a built in
	if arg_info == null:
		return obj.callv(method, in_args)
	
	var old := in_args.duplicate(true)
	var new := in_args.duplicate(true)
	var out := []
	var kwargs := {}
	
	# pop last dictionary, regardless
	if len(new) and new[-1] is Dictionary:
		if "kwargs" in arg_info:
			kwargs = new.pop_back()
		else:
			new.pop_back()
		
	# add the initial values up front
	for property in arg_info:
		if property in ["args", "kwargs"]:
			break
		elif len(new):
			var v = new.pop_front()
#			if arg_info[property].type != typeof(v):
#				var d = arg_info[property].get("default", null)
#				push_error("call_w_args: Wrong type '%' (%s) given for '%s'. Using default (%s) instead." % [arg_info[property].type_name, v, property, d ])
#				out.append(d)
#			else:
			out.append(v)
		else:
			out.append(arg_info[property].get("default", null))
	
	# insert the array
	if "args" in arg_info:
		if len(new):
			out.append(new)
		else:
			out.append(arg_info.args.get("default", []))
	
	# pop back in the kwargs
	if "kwargs" in arg_info:
		out.append(kwargs)
	
#	print(method.to_upper())
#	for i in len(out):
#		print("\t* %s\t\t%s\t\t%s" % [old[i] if i < len(old) else "??", out[i], arg_info.values()[i]])
	var got = obj.callv(method, out)
#	prints("CALLV:", method, out, got)
	return got

# find second last dictionary/object in a nested structure
static func get_penultimate(d: Variant, path: Array) -> Variant:
	var o = d
	for i in len(path)-1:
		if path[i] in o:
			o = o[path[i]]
		else:
			return null
	return o

static func has_at(d: Variant, path: Array) -> bool:
	var o = get_penultimate(d, path)
	return o and path[-1] in o

static func try_set_at(d: Variant, path: Array, value: Variant) -> bool:
	var o = get_penultimate(d, path)
	if o and path[-1] in o:
		o[path[-1]] = value
		return true
	else:
		return false

static func try_get_at(d: Variant, path: Array, default = null) -> Variant:
	var o = get_penultimate(d, path)
	if o and path[-1] in o:
		return o[path[-1]]
	else:
		return default

static func get_method_arg_info(obj: Object, meth: String) -> Variant:
	var methods = get_methods(obj) # TODO: Cache.
	return null if methods == null or not meth in methods else methods[meth]

static func get_methods(obj: Object) -> Variant:
	var script = obj.get_script()
	if script == null:
		return null
	var out := {}
	for line in script.source_code.split("\n", false):
		if line.begins_with("func "):
			var p = line.substr(5).split("(")
			var fname = p[0]
			var args = _parse_method_arguments(p[1].rsplit(")")[0])
			out[fname] = args
	return out

static func _parse_method_arguments(s: String) -> Dictionary:
	if s.strip_edges() == "":
		return {}
	
	var args = [["", ""]]
	var open := {}
	var in_name := true
	
	for c in s:
		if not len(open):
			if c == ":":
				in_name = false
				continue
			elif c == ",":
				args.append(["", ""])
				in_name = true
				continue
		match c:
			"{": UDict.tick(open, "{")
			"}": UDict.tick(open, "{", -1)
			"[": UDict.tick(open, "[")
			"]": UDict.tick(open, "[", -1)
			"(": UDict.tick(open, "(")
			")": UDict.tick(open, "(", -1)
		args[-1][0 if in_name else 1] += c
	
	var out := {}
	for i in len(args):
		var k = args[i][0].strip_edges()
		var v = args[i][1].split("=", true, 1)
		var type_name = v[0].strip_edges()
		out[k] = {}
		out[k].type_name = type_name
		out[k].type = UType.get_type_from_name(type_name)
		if len(v) == 2:
			out[k].default = str2var(v[1].strip_edges())
	return out

static func get_all_class_names() -> Array[String]:
	# should be faster than _global_script_classes
	return ProjectSettings.get_setting("_global_script_class_icons").keys()
	
static func get_class_from_name(classname: String) -> Variant:
	# TODO: cache this?
	for item in ProjectSettings.get_setting("_global_script_classes"):
		if item["class"] == classname:
			return load(item.path)
	return null

# does a class_name exist?
static func can_create(classname: String) -> bool:
	return classname in get_all_class_names()

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

# force grab the class_name from the source code.
static func _to_string_nice(obj: Object) -> String:
	var c := obj.get_class()
	var s: Script = obj.get_script()
	for line in s.source_code.split("\n", false, 2):
		if line.begins_with("class_name"):
			c = line.split("class_name", true, 1)[1].strip_edges()
			break
	var p = var2str(get_state(obj))
	p = p.replace(": ", ":").replace("\n", " ").replace('"', '').replace("{ ", "(").replace(" }", ")")
	return "%s%s" % [c, p]
