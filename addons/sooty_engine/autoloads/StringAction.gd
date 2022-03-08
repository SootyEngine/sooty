extends Node

const OPERATOR_ASSIGN := ["=", "+=", "-="]

var funcs := {
	"commas": func(x): return UString.commas(x),
	"humanize": func(x): return UString.humanize(x),
	"pick": _pick_cached
}

# Cache the pick function so it doesn't give the same option too often.
# Still random, just not as boring.
var _pick_cache := {}
func _pick_cached(x) -> Variant:
	# if a dictionary? treat as weighted dict
	if x is Dictionary:
		return URand.pick_weighted(x)
	
	# cache a duplicate to be randomly picked from
	if not x in _pick_cache:
		_pick_cache[x] = x.duplicate()
		_pick_cache[x].shuffle()
	
	var got = _pick_cache[x].pop_back()
	
	if len(_pick_cache[x]) == 0:
		_pick_cache[x] = x.duplicate()
		_pick_cache[x].shuffle()
	
	return got

# Test whether a command is true or false.
func test(condition: String) -> bool:
	var result = execute(condition, false)
#	prints("Test '%s' got '%s'." % [condition, result])
	return true if result else false

func execute(e: String, default = null, d: Dictionary={}) -> Variant:
	# Pipe value through a Callable?
	if "|" in e:
		var p := e.split("|", true, 1)
		var val = execute(p[0], default, d)
		var pipe_id := p[1]
		if pipe_id in funcs:
			return funcs[pipe_id].call(val)
	
	else:
		var expression := Expression.new()
		if expression.parse(e, PackedStringArray(d.keys())) == OK:
			var result = expression.execute(d.values(), State, false)
			if not expression.has_execute_failed():
				return result
#		push_error(expression.get_error_text())
	return default

func do(s: String) -> Variant:
	var got = null
	for a in s.split(";@"):
		got = _do(a)
	return got

func _do(s: String) -> Variant:
	var parts := _split_string(s)
	
	# assignment
	if len(parts) == 1:
		if s.ends_with("++"):
			return _do_assign([s.trim_suffix("++"), "+=", "1"])
			
		elif s.ends_with("--"):
			return _do_assign([s.trim_suffix("--"), "-=", "1"])
	
	# assignment
	if len(parts) > 2 and parts[1] in OPERATOR_ASSIGN:
		return _do_assign(parts)
	
	return _do_function(parts)

func _do_assign(parts: Array) -> Variant:
	var key = parts[0]
	if not key in State:
		push_error("No property '%s' in State." % key)
		return
	
	var eval = parts[1]
	var old_value = State[key]
	var new_value
	
	# simple variable assignment
	if len(parts) == 3:
		new_value = str_to_var(parts[2])
	# call a function assignment
	else:
		parts.pop_front() # pop property
		parts.pop_front() # pop eval
		new_value = _do_function(parts)
	
	match eval:
		"=": State._set(key, new_value)
		"+=": State._set(key, old_value + new_value)
		"-=": State._set(key, old_value - new_value)
	return State[key]

func _do_function(parts: Array) -> Variant:
	var args := []
	var fname: String = parts.pop_front()
	
	for p in parts:
		if ":" in p:
			var kv = p.split(":", true, 1)
			if not len(args) or not args[-1] is Dictionary:
				args.append({})
			args[-1][kv[0]] = str_to_var(kv[1])
		
		else:
			args.append(str_to_var(p))
	
	# if the function exists in func, just call that
	if fname in funcs:
		match len(args):
			0: return funcs[fname].call()
			1: return funcs[fname].call(args[0])
			2: return funcs[fname].call(args[0], args[1])
			3: return funcs[fname].call(args[0], args[1], args[2])
			4: return funcs[fname].call(args[0], args[1], args[2], args[3])
			5: return funcs[fname].call(args[0], args[1], args[2], args[3], args[4])
	
	var gname := fname
	
	if "." in fname:
		var p := fname.split(".", true, 1)
		gname = p[0]
		fname = p[1]
	
	var out = null
	for node in Global.get_tree().get_nodes_in_group("sa:%s" % gname):
		out = UObject.call_w_args(node, fname, args)
	return out
	
func _split_string(s: String) -> Array:
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

func str_to_var(s: String) -> Variant:
	# variable, leave unquoted
	if s.begins_with("$"):
		var prop := s.substr(1)
		if prop in State:
			return State[s.substr(1)]
		else:
			push_error("No property '%s' in State." % prop)
			return null
	
	# string
	elif s.begins_with('"'):
		return s.trim_prefix('"').trim_suffix('"')
	
	# array
	elif "," in s:
		var p = Array(s.split(","))
		for i in len(p):
			p[i] = str_to_var(p[i])
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
