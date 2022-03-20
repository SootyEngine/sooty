extends "res://addons/sooty_engine/autoloads/base_state.gd"

var _expr := Expression.new()

func do(command: String) -> Variant:
	# state method
	if command.begins_with(Sooty.S_ACTION_STATE):
		var call = command.substr(1)
		var args := UString.split_on_spaces(call)
		var method = args.pop_front()
		var converted_args := args.map(_str_to_var)
		return _call(method, converted_args)
	
	# group function
	elif command.begins_with(Sooty.S_ACTION_GROUP):
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
		
		var nodes := get_tree().get_nodes_in_group(group)
		var got
		if len(nodes):
			for node in nodes:
				got = UObject.call_w_args(node, method, converted_args)
			return got
		else:
			push_error("No nodes in group %s for %s(%s)." % [group, method, converted_args])
	
	# evaluate
	elif command.begins_with(Sooty.S_ACTION_EVAL):
		return _eval(command.substr(1))
	
	else:
		return _eval(command)

func _str_to_var(s: String) -> Variant:
	match s:
		"true": return true
		"false": return false
		"null": return null
	# state variable?
	if s.begins_with("$"):
		return _get(s.substr(1))
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

func _eval(expression: String, default = null) -> Variant:
	# assignments?
	for op in [" = ", " += ", " -= ", " *= ", " /= "]:
		if op in expression:
			var p := expression.split(op, true, 1)
			var property := p[0].strip_edges()
			if _has(property):
				var old_val = _get(property)
				var new_val = _eval(p[1].strip_edges())
				match op:
					" = ": _set(property, new_val)
					" += ": _set(property, old_val + new_val)
					" -= ": _set(property, old_val - new_val)
					" *= ": _set(property, old_val * new_val)
					" /= ": _set(property, old_val / new_val)
				return _get(property)
			else:
				push_error("No property '%s' in State." % property)
				return default
	
	# pipes
	if "|" in expression:
		var p := expression.split("|", true, 1)
		var got = _eval(p[0])
		return _pipe(got, p[1])
	
	var global = _globalize_functions(expression).strip_edges()
#	prints("(%s) >>> (%s)" %[expression, global])
	
	if _expr.parse(global, []) != OK:
		push_error(_expr.get_error_text())
	else:
		var result = _expr.execute([], self, false)
		if _expr.has_execute_failed():
			push_error("_eval(\"%s\") failed: %s." % [global, _expr.get_error_text()])
		else:
			return result
	return default

func _test(expression: String) -> bool:
	var got := true if _eval(expression) else false
#	print("_test(%s) == %s" % [expression, got])
	return got

func _pipe(value: Variant, pipes: String) -> Variant:
	for pipe in pipes.split("|"):
		var args = UString.split_on_spaces(pipe)
		var method = args.pop_front()
		if _has_method(method):
			value = _call(method, [value] + args.map(_eval))
		else:
			push_error("Can't pipe %s. No %s." % [value, method])
	return value

func _has(property: StringName):
	if Persistent._has(property):
		return true
	return super._has(property)

func _get(property: StringName):
	if Persistent._has(property):
		return Persistent._get(property)
	match str(property):
		"current_scene": return get_tree().current_scene
	return super._get(property)

func _set(property: StringName, value) -> bool:
	if Persistent._has(property):
		return Persistent._set(property, value)
	return super._set(property, value)

func _ready() -> void:
	super._ready()
	install_all("res://states")

func get_save_state() -> Dictionary:
	return _get_changed_states()

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
					var parent = _get_method_parent(method_name)
					out += "get_node(\"%s\").%s(" % [parent, method_name]
				out += UString.part(t, k+1+len(method_name), j)
				i = j + 1
				continue
		out += t[i]
		i += 1
	# add on the remainder.
	out += UString.part(t, i)
	return out
