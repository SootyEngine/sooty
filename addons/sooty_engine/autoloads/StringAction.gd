#@tool
extends Node

#const OP_ASSIGN := ["=", "+=", "-=", "*=", "/="]
const OP_ASSIGN := [" = ", " += ", " -= ", " *= ", " /= "]
const OP_RELATION := ["==", "!=", ">", "<", ">=", "<="]
const OP_ARITHMETIC := ["+", "-", "*", "/", "%"]
const OP_LOGICAL := ["and", "or", "not", "&&", "||", "!"]
const OP_ALL := OP_ASSIGN + OP_RELATION + OP_ARITHMETIC + OP_LOGICAL
const BUILT_IN := ["true", "false", "null"]

func do(command: String) -> Variant:
	# state method
	if command.begins_with("$"):
		var call = command.substr(1)
		var args := UString.split_on_spaces(call)
		var method = args.pop_front()
		var converted_args := args.map(_str_to_var)
		return State._call(method, converted_args)
	
	# node path method
	elif command.begins_with("^"):
		var call = command.substr(1)
		var args := UString.split_on_spaces(call)
		var head = args.pop_front()
		if "." in head:
			var p = args.pop_front().rsplit(".", true, 1)
			var node_path = p[0].replace(",", ".")
			var target := Global.get_tree().current_scene.get_node(node_path)
			var method = p[1]
			return UObject.call_w_args(target, method, args)
		else:
			push_error("Not implemented.")
	
	# group function
	elif command.begins_with("@"):
		var call = command.substr(1)
		var args := UString.split_on_spaces(call)
		var method = args.pop_front()
		var converted_args := args.map(_str_to_var)
		var group: String
		
		# node function
		if "." in method:
			var p = method.split(".", true, 1)
			group = "@" + p[0]
			method = p[1]
		# function
		else:
			group = "@." + method
		
		var nodes := Global.get_tree().get_nodes_in_group(group)
		var got
		if len(nodes):
			for node in nodes:
				got = UObject.call_w_args(node, method, converted_args)
			return got
		else:
			push_error("No nodes in group %s for %s(%s)." % [group, method, converted_args])
	
	# evaluate
	elif command.begins_with("~"):
		return State._eval(command.substr(1))
	
	else:
		return State._eval(command)

func _test(expression: String) -> bool:
	var got := true if State._eval(expression) else false
#	print("_test(%s) == %s" % [expression, got])
	return got

func _pipe(value: Variant, pipes: String) -> Variant:
	for pipe in pipes.split("|"):
		var args = UString.split_on_spaces(pipe)
		var method = args.pop_front()
		if State._has_method(method):
			value = State._call(method, [value] + args.map(State._eval))
		else:
			push_error("Can't pipe %s. No %s." % [value, method])
	return value

func _str_to_var(s: String) -> Variant:
	# builting
	match s:
		"true": return true
		"false": return false
		"null": return null
		"INF": return INF
		"-INF": return -INF
		"PI": return PI
		"TAU": return TAU
	
	# state variable?
	if s.begins_with("$"):
		return _get(s.substr(1))
	
	# is a string with spaces?
	if UString.is_wrapped(s, '"'):
		return UString.unwrap(s, '"')
	
	# evaluate
	if UString.is_wrapped(s, "<<", ">>"):
		var e := UString.unwrap(s, "<<", ">>")
		var got = State._eval(e)
#		print("EVAL %s -> %s" % [e, got])
		return got
	
	# array or dict?
	if "," in s or ":" in s:
		var args := s.split(",")
		var is_dict := ":" in args[0]
		var out = {} if is_dict else []
		for arg in args:
			if ":" in arg:
				var kv := arg.split(":", true, 1)
				var key := kv[0]
				var val = _str_to_var(kv[1])
				out[key] = val
			else:
				out.append(_str_to_var(arg))
		return out
	# float?
	if s.is_valid_float():
		return s.to_float()
	# int?
	if s.is_valid_int():
		return s.to_int()
	# must be a string?
	return s

# x = do_something(true, custom_func(0), sin(rotation))
# BECOMES
# x = _C.do_something.call(true, _C.custom_func.call(0), sin(rotation))
# this means functions defined in one Node, are usable by all as if they are their own.
func _globalize_functions(t: String) -> String:
	var i := 0
	var out := ""
	var off := 0
	while i < len(t):
		var j := t.find("(", i)
		# find a bracket.
		if j != -1:
			var k := j-1
			var method_name := ""
			# walk backwards
			while k >= 0 and t[k] in ".abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789":
				method_name = t[k] + method_name
				k -= 1
			# if head isn't empty, it's a function not wrapping brackets.
			if method_name != "":
				out += UString.part(t, i, k+1)
				# renpy inspired translations
				if method_name == "_":
					out += "tr("
				# don't wrap property methods, since those will be globally accessible from _get
				# don't wrap built in GlobalScope methods (sin, round, randf...)
				elif "." in method_name or method_name in UObject.GLOBAL_SCOPE_METHODS:
					out += "%s(" % method_name
				else:
					var parent = State._get_method_parent(method_name)
					out += "get_node(\"%s\").%s(" % [parent, method_name]
				out += UString.part(t, k+1+len(method_name), j)
				i = j + 1
				continue
		out += t[i]
		i += 1
	# add on the remainder.
	out += UString.part(t, i)
	return out
