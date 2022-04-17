@tool
extends Node

var _commands := {}
var _expr := Expression.new()
var symbol_calls := {
	
}

func add_command(call: Variant, desc := "", id := ""):
	var obj: Object = call.get_object() if call is Callable else call[0]
	var method: String = call.get_method() if call is Callable else call[1]
	id = id if id else method
	var args = UClass.get_arg_info(obj, method)
	var arg_names = args.map(func(x): return "%s:%s" % [x.name, UType.get_name_from_type(x.type)])
	print("> '%s' [%s]: %s" % [id, " ".join(arg_names), desc])
	_commands[id] = {
		call=call,
		desc=desc,
		args=args
	}

func _eval_replace_group_call(inside: String, group: String, nested: bool) -> String:
	if nested:
		var p := inside.split("(", true, 1)
		return "_SA_._call_group(\"@%s\", \"%s\", [%s])" % [group, p[0], p[1]]
	else:
		return "_SA_._call_group(\"@%s\", \"%s\", [%s])" % [group, group, inside]

# var action := '"%s %s %s %s %s" % [@test.name, @enemy.damage(score), @heal(333)]'
# var action := '[@test.name, @enemy.damage(score), @heal(333)]'
func preprocess_eval(eval: String):
	var tags := []
	var in_tag := false
	for c in eval:
		if c in "@$^":
			in_tag = true
			tags.append({type=c, tag="", prop="", full=c, is_nested=false, is_func=false})
		elif in_tag:
			if c in UString.CHARS_ALPHA_ALL + UString.CHARS_INTS + "_":
				tags[-1].full += c
				if not tags[-1].is_nested:
					tags[-1].tag += c
				else:
					tags[-1].prop += c
			# is nested?
			elif c == ".":
				tags[-1].is_nested = true
				tags[-1].full += c
			# is func?
			elif c == "(":
				in_tag = false
				tags[-1].is_func = true
			elif c == " ":
				in_tag = false
	
	for t in tags:
		if t.type == "@":
			if t.is_func:
				if t.is_nested:
					eval = UString.replace_between(eval, "@%s." % [t.tag], ")", _eval_replace_group_call.bind(t.tag, true))
				else:
					eval = UString.replace_between(eval, "@%s(" % [t.tag], ")", _eval_replace_group_call.bind(t.tag, false))
			else:
				eval = eval.replace(t.full, "_SA_.get_group_property(\"@%s\", \"%s\")" % [t.tag, t.prop])
		
		elif t.type == "$":
			if t.is_func:
				if t.is_nested:
					eval = eval.replace("$%s" % t.tag, "_S_.%s" % t.tag)
				else:
					eval = eval.replace(t.full + "(", "_S_._calls[\"%s\"].call(" % t.tag)
			else:
				if t.is_nested:
					eval = eval.replace(t.full, "_S_[\"%s.%s\"]" % [t.tag, t.prop])
				else:
					eval = eval.replace(t.full, "_S_[\"%s\"]" % [t.tag])
		
		elif t.type == "^":
			if t.is_func:
				if t.is_nested:
					eval = eval.replace("^%s" % t.tag, "_P_.%s" % t.tag)
				else:
					eval = eval.replace(t.full + "(", "_P_._calls[\"%s\"].call(" % t.tag)
			else:
				if t.is_nested:
					eval = eval.replace(t.full, "_P_[\"%s.%s\"]" % [t.tag, t.prop])
				else:
					eval = eval.replace(t.full, "_P_[\"%s\"]" % [t.tag])
					
	return eval

func test(e: String, context: Object = null) -> bool:
	return true if eval(e, context) else false

func do(command: String, context: Object = null) -> Variant:
	if not len(command):
		return
	
	# MATCH case argument
	if command == "_":
		return "_"
	
	# special VAR case.
	if command.begins_with("*"):
		return to_var(command)
	
	elif command.begins_with("@"):
		return do_group_action(command, context)
	
	elif command.begins_with("$"):
		return do_state_action(command, context)
	
	elif command.begins_with("^"):
		return do_state_action(command, context)
	
	elif command.begins_with("~"):
		return eval(command.substr(1).strip_edges(), context)
	
	push_error("Do action '%s'." % command)
	return null

func is_action(s: String) -> bool:
	return UString.get_leading_symbols(s) in Soot.ALL_ACTION_HEADS

func do_state_action(s: String, context: Object = null):
	var state: Node = State
	
	if s.begins_with("$"):
		s = s.substr(1)
	elif s.begins_with("^"):
		s = s.substr(1)
		state = Persistent
	
	var args := UString.split_outside(s, " ")
	var method = args.pop_front()
	return UObject.call_w_kwargs([state, method], args, true)

# vars are kept as strings, so can be auto type converted
func to_var(s: String) -> Variant:
	if s.begins_with("*"):
		s = s.substr(1)
	var out = []
	for part in UString.split_outside(s, " "):
		# dictionary key
		if ":" in part:
			if not len(out) or not out[-1] is Dictionary:
				out.append({})
			var kv = part.split(":", true, 1)
			out[-1][kv[0].strip_edges()] = kv[1].strip_edges()
		# array
		elif "," in part:
			out.append(Array(part.split(",")))
		# other
		else:
			out.append(part)
	out = out[0] if len(out) == 1 else out
	return out

# to_var keeps everything as strings so you can auto type convert where needed
# but if you want it to auto convert, use this
func var_to_variant(svar: Variant) -> Variant:
	match typeof(svar):
		TYPE_ARRAY:
			var out := []
			for i in len(svar):
				out.append(var_to_variant(svar[i]))
			return out
		
		TYPE_DICTIONARY:
			var out := {}
			for k in svar:
				out[k] = var_to_variant(svar[k])
			return out
		
		TYPE_STRING:
			var head := UString.get_leading_symbols(svar)
			if head in Soot.ALL_ACTION_HEADS:
				return do(svar)
			else:
				return UString.str_to_var(svar)
		_:
			push_error("Shouldn't happen.")
			return svar

# @action
func do_group_action(action: String, context: Object) -> Variant:
	var args := UString.split_outside(action, " ")
	var group: String = args.pop_front()
	return call_group_w_args(group, args, true)

# @action
# while it can call many members of a group, it returns the last non null value it gets
func call_group_w_args(group: String, args: Array, as_string_args := false) -> Variant:
	if group.begins_with("@"):
		group = group.substr(1)
	
	# node call
	var method: String = group
	if "." in group:
		var p = group.split(".", true, 1)
		group = "@:" + p[0]
		method = p[1]
	# function call
	else:
		group = "@." + group
	
	return _call_group(group, method, args, as_string_args)

#func _str_to_var(s: String) -> Variant:
#	# builting
#	match s:
#		"true": return true
#		"false": return false
#		"null": return null
#		"INF": return INF
#		"-INF": return -INF
#		"PI": return PI
#		"TAU": return TAU
#
#	# state variable?
#	if s.begins_with("$"):
#		return _get(s.substr(1))
#
#	# is a string with spaces?
#	if UString.is_wrapped(s, '"'):
#		return UString.unwrap(s, '"')
#
#	# evaluate
#	if UString.is_wrapped(s, "<<", ">>"):
#		var e := UString.unwrap(s, "<<", ">>")
#		var got = State._eval(e)
##		print("EVAL %s -> %s" % [e, got])
#		return got
#
#	# array or dict?
#	if "," in s or ":" in s:
#		var args := s.split(",")
#		var is_dict := ":" in args[0]
#		var out = {} if is_dict else []
#		for arg in args:
#			if ":" in arg:
#				var kv := arg.split(":", true, 1)
#				var key := kv[0]
#				var val = _str_to_var(kv[1])
#				out[key] = val
#			else:
#				out.append(_str_to_var(arg))
#		return out
#	# float?
#	if s.is_valid_float():
#		return s.to_float()
#	# int?
#	if s.is_valid_int():
#		return s.to_int()
#	# must be a string?
#	return s

func _call_group(group: String, method: String, args := [], as_string_args := false) -> Variant:
	var out: Variant
	var nodes := get_tree().get_nodes_in_group(group)
	for node in nodes:
		var got = UObject.call_w_kwargs([node, method], args, as_string_args)
		if got != null:
			out = got
	if len(nodes) == 0:
		push_warning("No nodes in group '%s' to call '%s' on with %s." % [group, method, args])
	return out

func get_group_property(group: String, property: String) -> Variant:
	return get_tree().get_first_node_in_group(group)[property]
#func _do_func(action: String, context: Object) -> Variant:
#	var args := UString.split_outside(action, " ")
#	var method: String = args.pop_front()
#	prints("FUNC", method, args)
#	if context.has_method("_call"):
#		return context._call(method, args, true)
#	else:
#		return UObject.call_w_kwargs([context, method], args, true)

func _context_has(context: Object, property: String) -> bool:
	if context.has_method("_has"):
		return context._has(property)
	else:
		return property in context

func eval(eval: String, context: Variant = null, default = null) -> Variant:
	if context == null:
		context = State
	
	# assignments?
	for op in [" = ", " += ", " -= ", " *= ", " /= "]:
		if op in eval:
			var p := eval.split(op, true, 1)
			var property := p[0].strip_edges()
			var target: Object = context
			
			# assigning to a state variable?
			if property.begins_with("$"):
				property = property.substr(1)
				target = State
			
			elif property.begins_with("^"):
				property = property.substr(1)
				target = Persistent
			
			# assigning to a group object?
			elif property.begins_with("@"):
				property = property.substr(1)
				target = get_tree().get_first_node_in_group(property)
				push_error("Assigning to @nodes isn't implemented.")
				return
				
			if _context_has(target, property):
				var old_val = target[property]
				var got_val = eval(p[1].strip_edges(), context)
				var new_val = old_val
				match op:
					" = ": new_val = got_val
					" += ": new_val += got_val
					" -= ": new_val -= got_val
					" *= ": new_val *= got_val
					" /= ": new_val /= got_val
				target[property] = new_val
				return target[property]
			else:
				push_error("No property '%s' in %s." % [property, target])
				return default
	
	# state_manager modified this to make it work with all it's child functions
	if context.has_method("_preprocess_eval"):
		eval = context._preprocess_eval(eval)
	
	# state shortcut
	eval = preprocess_eval(eval)
	
	if _expr.parse(eval, ["_T_", "_SA_", "_S_", "_P_"]) != OK:
		push_error("Failed _eval('%s'): %s." % [eval, _expr.get_error_text()])
	else:
		var result = _expr.execute([get_tree(), self, State, Persistent], context, false)
		if _expr.has_execute_failed():
			push_error("Failed _eval('%s'): %s." % [eval, _expr.get_error_text()])
		else:
			return result
	return default

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
			while k >= 0 and t[k] in UString.VAR_CHARS_NESTED:
				method_name = t[k] + method_name
				k -= 1
			# if head isn't empty, it's a function not wrapping brackets.
			if method_name != "":
				out += UString.part(t, i, k+1)
				# renpy inspired translation shortcut
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
