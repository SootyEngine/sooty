@tool
extends Resource
class_name StringAction

const OPERATOR_ASSIGN := ["=", "+=", "-="]

static func test(condition: String) -> bool:
	var result = execute(condition, false)
#	prints("Test '%s' got '%s'." % [condition, result])
	return true if result else false

static func execute(e: String, default = null, d: Dictionary={}):
	var expression := Expression.new()
	if expression.parse(e, PackedStringArray(d.keys())) == OK:
		var result = expression.execute(d.values(), State, false)
		if not expression.has_execute_failed():
			return result
#		push_error(expression.get_error_text())
	return default

static func do(s: String) -> Variant:
	var got = null
	for a in s.split(";"):
		got = _do(a)
	return got

static func _do(s: String) -> Variant:
	var parts := _split_string(s)
	
	# assignment
	if len(parts) == 1:
		if s.ends_with("++"):
			return _do_assign([s.trim_suffix("++"), "+=", "1"])
			
		elif s.ends_with("--"):
			return _do_assign([s.trim_suffix("--"), "-=", "1"])
	
	# assignment
	if len(parts) == 3 and parts[1] in OPERATOR_ASSIGN:
		return _do_assign(parts)
	
	return _do_function(parts)

static func _do_assign(parts: Array) -> Variant:
	var key = parts[0]
	if not key in State:
		push_error("No property '%s' in State." % key)
		return
	
	var old_value = State[key]
	var new_value = _str_to_var(parts[2])
	match parts[1]:
		"=": State._set(key, new_value)
		"+=": State._set(key, old_value + new_value)
		"-=": State._set(key, old_value - new_value)
	return State[key]

static func _do_function(parts: Array) -> Variant:
	var args := []
	var fname: String = parts.pop_front()
	
	for p in parts:
		if ":" in p:
			var kv = p.split(":", true, 1)
			if not len(args) or not args[-1] is Dictionary:
				args.append({})
			args[-1][kv[0]] = _str_to_var(kv[1])
		
		else:
			args.append(_str_to_var(p))
	
	var gname := fname
	
	if "." in fname:
		var p := fname.split(".", true, 1)
		gname = p[0]
		fname = p[1]
	
	var out = null
	for node in Global.get_tree().get_nodes_in_group("sa:%s" % gname):
		out = UObject.call_w_args(node, fname, args)
	return out
	
static func _split_string(s: String) -> Array:
	var out := [""]
	var in_quotes := false
	for c in s:
		if c == '"':
			if in_quotes:
				in_quotes = false
				out[-1] += '"'
			else:
				in_quotes = true
				if out[-1] == "":
					out[-1] += '"'
				else:
					out.append('"')
		
		elif c == " " and not in_quotes:
			if out[-1] != "":
				out.append("")
		
		else:
			out[-1] += c
	return out

static func _str_to_var(s: String) -> Variant:
	# variable, leave unquoted
	if s.begins_with("$"):
		var prop := s.substr(1)
		if prop in State:
			return State[s.substr(1)]
		else:
			push_error("No property '%s' in State." % prop)
			return null
	
	elif s.begins_with('"'):
		return s.trim_prefix('"').trim_suffix('"')
	
	# array
	elif "," in s:
		var p = Array(s.split(","))
		for i in len(p):
			p[i] = _str_to_var(p[i])
		return p
	
	elif s.is_valid_int():
		return s.to_int()
	elif s.is_valid_float():
		return s.to_float()
	elif s == "true":
		return true
	elif s == "false":
		return false
	elif s == "null":
		return null
	else:
		return s
#	# leave unquoted
#	elif "|" in s or s in ["true", "false", "null"] or s.is_valid_int() or s.is_valid_float():
#		return s
#
#	# string
#	return '"%s"' % s
