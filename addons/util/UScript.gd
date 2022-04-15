@tool
extends RefCounted
class_name UScript

func scan_scripts():
	for file in UFile.get_files("res://", "gd"):
		print(file)

static func get_arg_info(obj: Variant, meth: String) -> Array:
	return get_method_info(obj, meth).get("args", [])

# godot keeps dict key order, so we can return 
static func get_method_info(obj: Variant, meth: String) -> Dictionary:
	var methods = get_method_infos(obj) # TODO: Cache.
	return methods.get(meth, {})
#	return null if methods == null or not meth in methods else methods[meth]

static func get_method_infos(obj: Variant) -> Dictionary:
	var script: Script = obj.get_script()
	if script.has_meta("method_info"):
		return script.get_meta("method_info")
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
	script.set_meta("method_info", out)
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
		var type: int = UStringConvert.S2T_STR_TO_VAR
		var type_name: String = value[0].strip_edges()
		# no explicit type given, but a value exists?
		# let's assume
		var arg_info: = { name=name, type=type }
		if len(value) == 2:
			arg_info.default = UString.express(value[1].strip_edges(), obj)
		
		if type_name:
			arg_info.type = UType.get_type_from_name(type_name)
			if arg_info.type == TYPE_NIL:
				arg_info.type = type_name
		
		elif "default" in arg_info:
			arg_info.type = typeof(arg_info.default)
		
		out.append(arg_info)
	return out
