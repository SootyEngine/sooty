@tool
extends RefCounted
class_name UReflect

func scan_scripts():
	for file in UFile.get_files("res://", "gd"):
		print(file)

static func get_arg_info(object: Variant, meth: String) -> Array:
	return get_method_info(object, meth).get("args", [])

static func get_script_methods(object: Object, skip_private := true, skip_get := true, skip_set := true) -> Dictionary:
	if object.has_method("_get_script_methods"):
		return object._get_script_methods()
	
	var out := {}
	for m in object.get_method_list():
		if m.flags & METHOD_FLAG_FROM_SCRIPT != 0 and not m.name[0] == "@":
			if skip_private and m.name[0] == "_":
				continue
			if skip_get and m.name.begins_with("get_"):
				continue
			if skip_set and m.name.begins_with("set_"):
				continue
			out[m.name] = m
	
	return out

# godot keeps dict key order, so we can return 
static func get_method_info(object: Variant, meth: String, private := false) -> Dictionary:
	var methods = get_methods(object, private) # TODO: Cache.
	return methods.get(meth, {})

static func get_methods(object: Variant, private := false) -> Dictionary:
	if object.has_method("_get_methods"):
		return object._get_methods()
	
	var out := {}
	var script: Script = object.get_script()
	var safety := 20
	
	# collect not only this scripts methods, but it's base_script, parents.
	while script and safety > 0:
		for line in script.source_code.split("\n", false):
			if line.begins_with("func "):
				var p = line.substr(5).split("(")
				var fname = p[0]
				
				# skip private functions
				if not private and fname.begins_with("_"):
					continue
				
				var end = p[1].rsplit(")")
				var sargs = end[0]
				var returns = end[1].split(":", true, 1)[0].strip_edges()
				var args = _parse_method_arguments(sargs, object)
				# TODO: get return type
				returns = UType.get_type_from_name(returns.trim_prefix("->").strip_edges())
				out[fname] = {args=args, returns=returns}
		
		script = script.get_base_script()
		safety -= 1
	
	# look for explicitly defined data
	if object.has_method("_get_method_info"):
		for method in out:
			var extra_info = object._get_method_info(method)
			if extra_info:
				UDict.merge(out[method], extra_info, true)
	
#	script.set_meta("cached_method_info", out)
	return out

# convert a string of arguments to argument info
static func _parse_method_arguments(s: String, obj: Variant = null) -> Dictionary:
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
		var name = args[i][0].strip_edges()
		var value = args[i][1].split("=", true, 1)
		var type: int = UStringConvert.S2T_STR_TO_VAR
		var type_name: String = value[0].strip_edges()
		# no explicit type given, but a value exists?
		# let's assume
		var arg_info: = { name=name, type=type }
		if len(value) == 2:
			arg_info.default = UString.express(value[1].strip_edges(), obj)
		
		if type_name:
			arg_info.type = UType.get_type_from_name(type_name)
			# null type, yet a name exists?
			# so it's either a class_name or an Enum
			if arg_info.type == TYPE_NIL:
				arg_info.type = type_name
		
		elif "default" in arg_info:
			arg_info.type = typeof(arg_info.default)
		
		out[name] = arg_info
	return out
