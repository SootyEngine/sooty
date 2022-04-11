@tool
extends RefCounted
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

# find a child of type
static func find_child_of_type(parent: Node, child_type: Variant) -> Node:
	for i in parent.get_child_count():
		var c := parent.get_child(i)
		if c is child_type:
			return c
	return null

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

static func get_script_methods(target: Object, skip_private := true, skip_get := true, skip_set := true) -> Dictionary:
	var out := {}
	for m in target.get_method_list():
		if m.flags & METHOD_FLAG_FROM_SCRIPT != 0 and not m.name[0] == "@":
			if skip_private and m.name[0] == "_":
				continue
			if skip_get and m.name.begins_with("get_"):
				continue
			if skip_set and m.name.begins_with("set_"):
				continue
			out[m.name] = m
	return out

static func get_operator_value(v):
	if v is Object:
		if v.has_method("_operator_get"):
			return v._operator_get()
	return v

# Properly divides an array as arguments for a function. Like python.
static func call_w_kwargs(call: Variant, in_args: Array = [], as_string_args := false, arg_info = null) -> Variant:
	var obj: Object = call.get_object() if call is Callable else call[0]
	var method: String = call.get_method() if call is Callable else call[1]
	if arg_info == null:
		arg_info = get_arg_info(obj, method)
	
	# no args mean it was probably not a script function but a built in
	if not len(arg_info):
		return obj.callv(method, in_args)
	
	var new := in_args.duplicate(true)
	var out := []
	var kwargs
	var has_kwargs := false
	
	# too many arguments?
	if len(new) > len(arg_info):
		var left_over := []
		while len(new) > len(arg_info):
			left_over.append(new.pop_back())
		push_error("Passed too many arguments to %s. Trimming %s." % [method, left_over])
	
	# are kwargs wanted?
	if len(new) and arg_info[-1].name == "kwargs":
		# is last string a dict?
		if as_string_args:
			if new[-1] is String and ":" in new[-1]:
				kwargs = new.pop_back()
				has_kwargs = true
		# is last item a dict?
		else:
			if new[-1] is Dictionary:
				kwargs = new.pop_back()
				has_kwargs = true
	
	# strings to their type
	if as_string_args:
		# convert leading arguments
		for i in len(new):
			new[i] = UString.str_to_type(in_args[i], arg_info[i].type)
			prints("%s -> %s == %s" % [in_args[i], arg_info[i].type, new[i]])
		# convert kwargs
		if has_kwargs:
			kwargs = UString.str_to_type(kwargs, TYPE_DICTIONARY, arg_info[-1].get("default", {}))
	
	print("OK ", in_args, new)
	
	# add the initial values up front
	for arg in arg_info:
		if arg.name in ["args", "kwargs"]:
			break
		
		elif len(new):
			out.append(new.pop_front())
		
		# pad the arguments with their defaults, so kwarg can always be at the end
		elif "default" in arg:
			out.append(arg.default)
		
		elif has_kwargs:
			push_error("For kwargs to work, you need default values.")
			out.append(null)
	
	# TODO: allow leftover array to be passed as second last argument if kwargs, or last if no kwargs
	# insert the array
#	if "args" in arg_info:
#		if len(new):
#			out.append(new)
#		else:
#			out.append(arg_info.args.get("default", []))
	
	# pop back in the kwargs
	if has_kwargs:
		out.append(kwargs)
	
#	print(method.to_upper())
#	for i in len(out):
#		print("\t* %s\t\t%s\t\t%s" % [old[i] if i < len(old) else "??", out[i], arg_info.values()[i]])
	
	
	var got = obj.callv(method, out)# callablev(call, out) if call is Callable else obj.callv(method, out)
	prints("CALLV:", method, out, got)
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

static func get_arg_info(obj: Variant, meth: String) -> Array:
	return get_method_info(obj, meth).get("args", [])

# godot keeps dict key order, so we can return 
static func get_method_info(obj: Variant, meth: String) -> Dictionary:
	var methods = get_methods(obj) # TODO: Cache.
	return methods.get(meth, {})
#	return null if methods == null or not meth in methods else methods[meth]

static func get_methods(obj: Variant) -> Dictionary:
	var script = obj.get_script()
	var out := {}
	if script:
		for line in script.source_code.split("\n", false):
			if line.begins_with("func "):
				var p = line.substr(5).split("(")
				var fname = p[0]
				var end = p[1].rsplit(")")
				var sargs = end[0]
				var returns = end[1].split(":", true, 1)[0].strip_edges()
				var args = _parse_method_arguments(sargs, obj)
				# TODO: get return type
				returns = UType.get_type_from_name(returns.trim_prefix("->").strip_edges())
				out[fname] = {args=args, returns=returns}
	return out

# convert a string of arguments to argument info
static func _parse_method_arguments(s: String, obj: Variant = null) -> Array:
	if s.strip_edges() == "":
		return []
	
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
	
	var out := []
	for i in len(args):
		var name = args[i][0].strip_edges()
		var value = args[i][1].split("=", true, 1)
		var type: int = UString.S2T_STR_TO_VAR
		var type_name: String = value[0].strip_edges()
		# no explicit type given, but a value exists?
		# let's assume
		var arg_info: = { name=name, type=type }
		if len(value) == 2:
			arg_info.default = UString.express(value[1].strip_edges(), obj)
		
		if type_name:
			arg_info.type = UType.get_type_from_name(type_name)
		
		elif "default" in arg_info:
			arg_info.type = typeof(arg_info.default)
		
		out.append(arg_info)
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
