@tool
extends Node

const OP_ASSIGN := ["=", "+=", "-=", "*=", "/="]
const OP_RELATION := ["==", "!=", ">", "<", ">=", "<="]
const OP_ARITHMETIC := ["+", "-", "*", "/", "%"]
const OP_LOGICAL := ["and", "or", "not", "&&", "||", "!"]
const OP_ALL := OP_ASSIGN + OP_RELATION + OP_ARITHMETIC + OP_LOGICAL
const BUILT_IN := ["true", "false", "null"]

var pipes := {
	"commas": func(x): return UString.commas(UObject.get_operator_value(x)),
	"humanize": func(x): return UString.humanize(UObject.get_operator_value(x)),
	"plural": func(x, one:="%s", more:="%s's", none:="%s's"): return UString.plural(UObject.get_operator_value(x), one, more, none),
	"ordinal": func(x): return UString.ordinal(UObject.get_operator_value(x)),
	
	"pick": _pipe_pick,
	"test": _pipe_test,
	"stutter": _pipe_stutter,
	
	"capitalize": func(x): return str(x).capitalize(), 
	"lowercase": func(x): return str(x).to_lower(),
	"uppercase": func(x): return str(x).to_upper(),
}

func pipe(value: Variant, pipe: String) -> Variant:
	var args := split_string(pipe)
	var fname = args.pop_front()
	if fname in pipes:
		# convert args to strings.
		for i in len(args):
			args[i] = str_to_var(args[i])
		return UObject.call_callable(pipes[fname], [value] + args)
	return value

static func _pipe_test(s: Variant, ontrue := "yes", onfalse := "no") -> String:
	return ontrue if s else onfalse

static func _pipe_stutter(s) -> String:
	var parts := str(s).split(" ")
	for i in len(parts):
		if len(parts[i]) > 2:
			parts[i] = parts[i].substr(0, 1 if randf()>.5 else 2) + "-" + parts[i].to_lower()
	return " ".join(parts)

# Cache the pick function so it doesn't give the same option too often.
# Still random, just not as boring.
var _pick_cache := {}
func _pipe_pick(x) -> Variant:
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
	# TODO: Don't use execute. Rework to use _operator_get
	var parts := split_string(condition)
	for i in len(parts):
		parts[i] = _str_to_test_str(parts[i])
	var new_condition = " ".join(parts)
	var result = execute(new_condition, false)
	return true if result else false

func _str_to_test_str(s: String):
	if s.begins_with("$"):
		s = s.substr(1)
		var got = State._get(s)
		got = UObject.get_operator_value(got)
		return var2str(got)
	elif s in BUILT_IN or s in OP_ALL:
		return s
	else:
		return var2str(str_to_var(s))

func execute(e: String, default = null, d: Dictionary={}) -> Variant:
	# Pipe value through a Callable?
	if "|" in e:
		var p := e.rsplit("|", true, 1)
		var val = execute(p[0], default, d)
		return pipe(val, p[1])
	
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
	for a in s.split(";"):
		if a.begins_with("=="):
			push_error("Not implemented.")
			pass
		else:
			got = _do(a.strip_edges())
	return got

func _do(s: String) -> Variant:
	if "(" in s:
		return execute(s)
	
	var parts := split_string(s)
	# assignment
	if len(parts) == 1:
		if s.ends_with("++"):
			return _do_assign([s.trim_suffix("++"), "+=", "1"])
			
		elif s.ends_with("--"):
			return _do_assign([s.trim_suffix("--"), "-=", "1"])
	
	# assignment
	if len(parts) > 2 and parts[1] in OP_ASSIGN:
		return _do_assign(parts)
	
	return _do_function(parts)

func _do_assign(parts: Array) -> Variant:
	var key = parts[0]
	
	if key.begins_with("$"):
		key = key.substr(1)
		# TODO: currently everything on the left side is being treated as a state path.
		
	if not State._has(key):
		push_error("No property '%s' in State." % key)
		return
	
	var eval = parts[1]
	var old_value = State._get(key)
	var new_value
	
	if old_value is Callable:
		push_error("'%s' is a function but was treated as a property." % key)
		return
	
	# simple variable assignment
	if len(parts) == 3:
		new_value = str_to_var(parts[2])
	
	# call a function assignment
	else:
		assert(false)
		# TODO: "X + Y" shouldnt be "X(Y)"
		parts.pop_front() # pop property
		parts.pop_front() # pop eval
		new_value = _do_function(parts)
	
	if old_value is Object:
		var target = old_value
		if not target.has_method("_operator_set") or not target.has_method("_operator_get"):
			push_error("Object requires _operator_get/_operator_set to do assign. %s" % target)
			return null
		
		match eval:
			"=": target._operator_set(new_value)
			"+=": target._operator_set(target._operator_get() + new_value)
			"-=": target._operator_set(target._operator_get() - new_value)
		
		return target._operator_get()
		
	else:
		match eval:
			"=": State._set(key, new_value)
			"+=": State._set(key, old_value + new_value)
			"-=": State._set(key, old_value - new_value)
		
		return State._get(key)

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
	
	var out = null
	
	if fname.begins_with("$"):
		fname = fname.substr(1)
		
		out = UObject.call_w_args(State, fname, args)
		
	else:
		# if the function exists in func, just call that
		if fname in pipes:
			return UObject.call_callable(pipes[fname], args)
		
		var gname := fname
		
		if "." in fname:
			var p := fname.split(".", true, 1)
			gname = p[0]
			fname = p[1]
		
		var group := "sa:%s" % gname
		var nodes :=  Global.get_tree().get_nodes_in_group(group)
		if len(nodes) == 0:
			push_error("No node for %s" % [[gname, fname, args]])
		for node in nodes:
			out = UObject.call_w_args(node, fname, args)
	
	return out
	
static func split_string(s: String) -> Array:
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
		var key = s.substr(1)
		if State._has(key):
			return State._get(key)
		
		else:
			push_error("No property '%s' in State." % s)
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
