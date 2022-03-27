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
		
		if "." in method:
			var p = method.split(".", true, 1)
			group = p[0]
			method = p[1]
		else:
			group = "sa:" + method
		
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


#var pipes := {
#	"commas": func(x): return UString.commas(UObject.get_operator_value(x)),
#	"humanize": func(x): return UString.humanize(UObject.get_operator_value(x)),
#	"plural": func(x, one:="%s", more:="%s's", none:="%s's"): return UString.plural(UObject.get_operator_value(x), one, more, none),
#	"ordinal": func(x): return UString.ordinal(UObject.get_operator_value(x)),
#
#	"pick": _pipe_pick,
#	"test": _pipe_test,
#	"stutter": _pipe_stutter,
#
#	"capitalize": func(x): return str(x).capitalize(), 
#	"lowercase": func(x): return str(x).to_lower(),
#	"uppercase": func(x): return str(x).to_upper(),
#}

#func pipe(value: Variant, pipe: String) -> Variant:
#	var args := split_string(pipe)
#	var fname = args.pop_front()
#	if fname in pipes:
#		# convert args to strings.
#		for i in len(args):
#			args[i] = str_to_var(args[i])
#		return UObject.call_callable(pipes[fname], [value] + args)
#	return value



# Test whether a command is true or false.
#func test(condition: String) -> bool:
#	# TODO: Don't use execute. Rework to use _operator_get
#	var parts := split_string(condition)
#	for i in len(parts):
#		parts[i] = _str_to_test_str(parts[i])
#	var new_condition = " ".join(parts)
#	var result = execute(new_condition, false)
#	return true if result else false

#func _str_to_test_str(s: String):
#	if s.begins_with("$"):
#		s = s.substr(1)
#		var got = State._get(s)
#		got = UObject.get_operator_value(got)
#		return var2str(got)
#	elif s in BUILT_IN or s in OP_ALL:
#		return s
#	else:
#		return var2str(str_to_var(s))

#func execute(e: String, default = null, d: Dictionary={}) -> Variant:
#	# Pipe value through a Callable?
#	if "|" in e:
#		var p := e.rsplit("|", true, 1)
#		var val = execute(p[0], default, d)
#		return pipe(val, p[1])
#
#	else:
#		var expression := Expression.new()
#		if expression.parse(e, PackedStringArray(d.keys())) == OK:
#			var result = expression.execute(d.values(), State, false)
#			if not expression.has_execute_failed():
#				return result
##		push_error(expression.get_error_text())
#	return default

#func do(s: String) -> Variant:
#	var got = null
#	for a in s.split(";"):
#		if a.begins_with("=="):
#			push_error("Not implemented.")
#			pass
#		else:
#			got = _do(a.strip_edges())
#	return got

#func _do(s: String) -> Variant:
#	if "(" in s:
#		return execute(s)
#
#	var parts := split_string(s)
#	# assignment
#	if len(parts) == 1:
#		if s.ends_with("++"):
#			return _do_assign([s.trim_suffix("++"), "+=", "1"])
#
#		elif s.ends_with("--"):
#			return _do_assign([s.trim_suffix("--"), "-=", "1"])
#
#	# assignment
#	if len(parts) > 2 and parts[1] in OP_ASSIGN:
#		return _do_assign(parts)
#
#	return _do_function(parts)
#
#func _do_assign(parts: Array) -> Variant:
#	var key = parts[0]
#
#	if key.begins_with("$"):
#		key = key.substr(1)
#		# TODO: currently everything on the left side is being treated as a state path.
#
#	if not State._has(key):
#		push_error("No property '%s' in State." % key)
#		return
#
#	var eval = parts[1]
#	var old_value = State._get(key)
#	var new_value
#
#	if old_value is Callable:
#		push_error("'%s' is a function but was treated as a property." % key)
#		return
#
#	# simple variable assignment
#	if len(parts) == 3:
#		new_value = str_to_var(parts[2])
#
#	# call a function assignment
#	else:
#		assert(false)
#		# TODO: "X + Y" shouldnt be "X(Y)"
#		parts.pop_front() # pop property
#		parts.pop_front() # pop eval
#		new_value = _do_function(parts)
#
#	if old_value is Object:
#		var target = old_value
#		if not target.has_method("_operator_set") or not target.has_method("_operator_get"):
#			push_error("Object requires _operator_get/_operator_set to do assign. %s" % target)
#			return null
#
#		match eval:
#			"=": target._operator_set(new_value)
#			"+=": target._operator_set(target._operator_get() + new_value)
#			"-=": target._operator_set(target._operator_get() - new_value)
#
#		return target._operator_get()
#
#	else:
#		match eval:
#			"=": State._set(key, new_value)
#			"+=": State._set(key, old_value + new_value)
#			"-=": State._set(key, old_value - new_value)
#
#		return State._get(key)
#
#func get_properties(s: String) -> Array:
#	var args := []
#	var parts := split_string(s)
#	for p in parts:
#		if ":" in p:
#			var kv = p.split(":", true, 1)
#			if not len(args) or not args[-1] is Dictionary:
#				args.append({})
#			args[-1][kv[0]] = str_to_var(kv[1])
#		else:
#			args.append(str_to_var(p))
#	return args
#
#func _do_function(parts: Array) -> Variant:
#	var args := []
#	var fname: String = parts.pop_front()
#
#	for p in parts:
#		if ":" in p:
#			var kv = p.split(":", true, 1)
#			if not len(args) or not args[-1] is Dictionary:
#				args.append({})
#			args[-1][kv[0]] = str_to_var(kv[1])
#
#		else:
#			args.append(str_to_var(p))
#
#	var out = null
#
#	if fname.begins_with("$"):
#		fname = fname.substr(1)
#
#		out = UObject.call_w_args(State, fname, args)
#
#	else:
#		# if the function exists in func, just call that
#		if fname in pipes:
#			return UObject.call_callable(pipes[fname], args)
#
#		var gname := fname
#
#		if "." in fname:
#			var p := fname.split(".", true, 1)
#			gname = p[0]
#			fname = p[1]
#
#		var group := "sa:%s" % gname
#		var nodes :=  Global.get_tree().get_nodes_in_group(group)
#		if len(nodes) == 0:
#			push_error("No node for %s" % [[gname, fname, args]])
#		for node in nodes:
#			out = UObject.call_w_args(node, fname, args)
#
#	return out
#
#static func split_string(s: String) -> Array:
#	var out := [""]
#	var in_quotes := false
#	for c in s:
#		if c == '"':
#			if in_quotes:
#				in_quotes = false
#				out[-1] += '"'
#			else:
#				in_quotes = true
#				if out[-1] == "":
#					out[-1] += '"'
#				else:
#					out.append('"')
#
#		elif c == " " and not in_quotes:
#			if out[-1] != "":
#				out.append("")
#
#		else:
#			out[-1] += c
#	return out
#
#func str_to_var(s: String) -> Variant:
#	# variable, leave unquoted
#	if s.begins_with("$"):
#		var key = s.substr(1)
#		if State._has(key):
#			return State._get(key)
#
#		else:
#			push_error("No property '%s' in State." % s)
#			return null
#
#	# string
#	elif s.begins_with('"'):
#		return s.trim_prefix('"').trim_suffix('"')
#
#	# array
#	elif "," in s:
#		var p = s.split(",")
#		var is_dict := ":" in p[0]
#		var out = {} if is_dict else []
#		for i in len(p):
#			if is_dict:
#				var p2 = p.split(":", true, 1)
#				out[p2[0]] = str_to_var(p2[1])
#			else:
#				p[i] = str_to_var(p[i])
#		return p
#
#	elif s.is_valid_int():
#		return s.to_int()
#	elif s.is_valid_float():
#		return s.to_float()
#	elif s == "true":
#		return true
#	elif s == "false":
#		return false
#	elif s == "null":
#		return null
#	else:
#		return s
#	# leave unquoted
#	elif "|" in s or s in ["true", "false", "null"] or s.is_valid_int() or s.is_valid_float():
#		return s
#
#	# string
#	return '"%s"' % s
