@tool
extends RefCounted
class_name UString

const CHAR_QUOTE_OPENED := "“"
const CHAR_QUOTE_CLOSED := "”"
const CHAR_INNER_QUOTE_OPENED := "‘"
const CHAR_INNER_QUOTE_CLOSED := "’"

static func express(s: String, base_instance: Object = null, default = null) -> Variant:
	var e := Expression.new()
	if not UError.error(e.parse(s)):
		var got = e.execute([], base_instance)
		if not e.has_execute_failed():
			return got
		else:
			push_error(e.get_error_text())
	return default

static func get_string(v: Variant, id: String, default := str(v)) -> String:
	if v is Object and v.has_method("get_string"):
		var got: String = v.get_string(id)
		if got:
			return got
	return default

# Replace "quotes" with “quotes”.
static func fix_quotes(input: String) -> String:
	var out := ""
	var open := false
	for c in input:
		if c == '"':
			open = not open
			out += CHAR_QUOTE_OPENED if open else CHAR_QUOTE_CLOSED
		else:
			out += c
	return out

# Get a list of strings that are similar, sorted by similarity.
static func find_most_similar(to: String, options: Array, threshold := 0.25) -> Array[String]:
	var out := []
	for option in options:
		var sim := to.similarity(option)
		if sim >= threshold:
			out.append([sim, option])
	# sort by similarity
	out.sort_custom(func(a, b): return a[0] > b[0])
	# only return the strings
	return out.map(func(x): return x[1])

# Pushes an error, showing potentially desired options.
static func push_error_similar(error: String, to: String, options: Array, threshold := 0.25):
	var similar := find_most_similar(to, options, threshold)
	if len(similar):
		push_error(error + " Did you mean: %s?" % ", ".join(similar))
	else:
		push_error(error)

# Works like python list[begin:end]
static func part(s: String, from: int = 0, to = null) -> String:
	if to == null:
		to = len(s)
	elif to < 0:
		to = len(s) - to
	return s.substr(from, to-from)

static func is_at(s: String, tag: String, index: int) -> bool:
	for i in len(tag):
		if i+index >= len(s) or s[i+index] != tag[i]:
			return false
	return true

# Removes a string from between tags, and returns [cleaned string, inner string].
static func extract(s: String, head: String, tail: String, strip_edges: bool = true) -> Dictionary:
	if head == "" or tail == "":
		push_error("Must pass a head and tail.")
		return {outside=s, inside=""}
	var a := s.find(head)
	if a != -1:
		var b := a + len(head)
		var found_at := -1
		var in_tag := 1
		while b < len(s):
			if is_at(s, head, b):
				in_tag += 1
			elif is_at(s, tail, b):
				in_tag -= 1
				if not in_tag:
					found_at = b
					break
			b += 1
		
		if found_at != -1:
			var outer := part(s, 0, a).strip_edges(false, strip_edges) + part(s, found_at+len(head)).strip_edges(strip_edges, false)
			var inner := part(s, a+len(head), found_at)
			return {outside=outer, inside=inner}
		else:
			var outer := part(s, 0, a).strip_edges(false, strip_edges)
			var inner :=  part(s, a+len(head))
			return {outside=outer, inside=inner}
	
	else:
		return {outside=s, inside=""}

# split, but not if inside something
static func split_outside(s: String, split_on: String) -> Array:
	var out := []
	var open := {}
	var last := 0
	var i := 0
	var in_quotes := false
	var in_s_quotes := false
	while i < len(s):
		match s[i]:
			'"': in_quotes = not in_quotes
			"'": in_s_quotes = not in_s_quotes
			"{": _tick(open, "{")
			"}": _tick(open, "{", -1)
			"[": _tick(open, "[")
			"]": _tick(open, "[", -1)
			"(": _tick(open, "(")
			")": _tick(open, "(", -1)
		if not in_quotes and not in_s_quotes and not len(open) and begins_at(s, split_on, i):
			out.append(s.substr(last, i-last))
			i += len(split_on)
			last = i
		else:
			i += 1
	if last < len(s):
		out.append(s.substr(last, i-last))
	return out

static func _tick(d: Dictionary, key, amount: int = 1):
	d[key] = d[key] + amount if key in d else amount
	if d[key] == 0:
		d.erase(key)

static func begins_at(s: String, head: String, at: int) -> bool:
	for i in len(head):
#		if at+i > len(head):
#			return false
		if at+i >= len(s) or not s[at+i] == head[i]:
			return false
	return true

static func split_between(s: String, head: String, tail = null) -> PackedStringArray:
	var out := PackedStringArray()
	tail = head if tail == null else tail
	
	# edge case hack
	var x := s.find(head)
	var y := s.find(tail)
	if y != -1 and ((x != -1 and y < x) or x == -1):
		s = head + s
	
	while true:
		var a = s.find(head)
		if a == -1: break
		var b = s.find(tail, a+len(head))
		var inner
		var p = part(s, 0, a)
		
		if b == -1:
			inner = part(s, a+len(head))
			s = ""
		
		else:
			inner = part(s, a+len(head), b)
			s = part(s, b+len(tail))
		
		if p:
			out.append(p)
		
		out.append(head + inner + tail)
	
	if s:
		out.append(s)
	
	return out

# with_index: means the location in the main string will also be returned.
static func replace_between(s: String, head: String, tail: String, call: Callable, with_index := false) -> String:
	var index := 0
	while true:
		index = s.find(head, index)
		if index == -1: break
		var b = s.find(tail, index+len(head))
		if b == -1: break
		var inner = part(s, index+len(head), b)
		if head in inner:
			index += len(head)
			continue
		
		var got = str(call.call(index, inner) if with_index else call.call(inner))
		
		if got:
			s = part(s, 0, index) + got + part(s, b+len(tail))
			index += len(got)
		else:
			s = part(s, 0, index) + part(s, b+len(tail))
	return s

static func find_either(s: String, items: Array, from := 0) -> Array:
	var n := INF
	var first := ""
	for item in items:
		var i := s.find(item, from)
		if i != -1 and i < n:
			n = i
			first = item
	return [first, n]

static func split_on_next(s: String, items: Array) -> Array:
	var f := find_either(s, items)
	var token: String = f[0]
	if token == "":
		return ["", "", s]
	var p := s.split(token, true, 1)
	var token_str: String = p[0].strip_edges(false, true)
	var left_over: String = "" if len(p) == 1 else p[1].strip_edges(true, false)
	return [token, token_str, left_over]

# splits a string on spaces, respecting wrapped strings.
#static func split_on_spaces(s: String) -> Array:
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

static func is_capitalized(s: String) -> bool:
	return s[0] == s[0].to_upper()

static func is_wrapped(s: String, head: String, tail=null) -> bool:
	return s.begins_with(head) and s.ends_with(tail if tail else head)

static func unwrap(s: String, head: String, tail=null) -> String:
	return s.trim_prefix(head).trim_suffix(tail if tail else head)

# 1234567 => 1,234,567
static func commas(number: Variant) -> String:
	var string := str(number)
	var is_neg := string.begins_with("-")
	if is_neg:
		string = string.substr(1)
	var mod = len(string) % 3
	var out = ""
	for i in len(string):
		if i != 0 and i % 3 == mod:
			out += ","
		out += string[i]
	return "-" + out if is_neg else out

const SIZES := {1_000_000_000:"B", 1_000_000:"M", 1_000:"k"}
static func humanize(value: int) -> String:
	var is_neg := value < 0
	if is_neg:
		value = -value
	for size in SIZES:
		if value > size:
			var out := "%.2f%s" % [(value / float(size)), SIZES[size]]
			return "-" + out if is_neg else out
	return str(-value) if is_neg else str(value)

static func plural(x: Variant, one := "%s", more = "%s's", none := "%s's") -> String:
	var out := none if int(x) == 0 else one if int(x) == 1 else more
	return out % x if "%s" in out else out

static func ordinal(n: Variant, one := "%sst", two := "%snd", three := "%srd", other := "%sth") -> String:
	if n is String:
		n = n.to_int()
	var ord = {1: one, 2: two, 3: three}.get(n if n % 100 < 20 else n % 10, other)
	return ord % str(n) if "%s" in ord else ord

static func split_chars(s: String) -> Array:
	var out := []
	for c in s:
		out.append(c)
	return out

static func count_leading(s: String, chr := " ") -> int:
	var out := 0
	for c in s:
		if c == chr:
			out += 1
		else:
			break
	return out

#static func count_leading_tabs(s: String) -> int:
#	var out := 0
#	for c in s:
#		match c:
#			"\t": out += 1#4
##			" ": out += 1
#			_: break
##	out /= 4
#	return out

static func get_key_var(s: String, split_on := ":") -> Array:
	var i := s.find(split_on)
	if i != -1:
		var k := s.substr(0, i).strip_edges()
		var v := s.substr(i+1).strip_edges()
		return [k, v]
	else:
		return [s, ""]

static func str_to_var(s: String) -> Variant:
	var a := s.replace("_", "")
	# int
	if a.is_valid_int(): return a.to_int() 
	# float
	if a.is_valid_float(): return a.to_float()
	# bool
	if a in ["true", "false"]: return a == "true"
	# color
	if a.is_valid_html_color(): return Color(a)
	# string
	return s

# converts strings in comma seperated field to a type
static func str_to_array(s: String, type: int = -1) -> Array:
	return Array(s.split(",")).map(func(x): return str_to_type(x.strip_edges(), type))

static func str_to_color(s: String) -> Color:
	# from name?
	var out := Color.WHITE
	var i := out.find_named_color(s)
	if i != -1:
		return out.get_named_color(i)
	# from hex?
	if s.is_valid_html_color():
		return Color(s)
	# from floats?
	if "," in s:
		# form (0,0,0,0)
		if is_wrapped(s, "(", ")"):
			s = unwrap(s, "(", ")")
		# floats?
		return _set_type(Color.WHITE, str_to_array(s, TYPE_FLOAT))
	push_error("Can't convert '%s' to color." % s)
	return out

static func str_to_dict(s: String) -> Dictionary:
	if is_wrapped(s, "{", "}"):
		return express(s)
	else:
		var out := {}
		for part in split_outside(s, " "):
			var kv = part.split(":")
			out[kv[0].strip_edges()] = str_to_var(kv[1].strip_edges())
		return out

static func _set_type(v: Variant, vals: Array) -> Variant:
	for i in len(vals):
		v[i] = vals[i]
	return v

static func str_to_type(s: String, type: int, default = null) -> Variant:
	match type:
		-1: return express(s)
		TYPE_NIL: return null
		TYPE_BOOL: return s == "true"
		TYPE_INT: return s.replace("_", "").to_int()
		TYPE_FLOAT: return s.replace("_", "").to_float()
		TYPE_STRING: return s
		TYPE_VECTOR2: return _set_type(Vector2.ZERO, str_to_array(s, TYPE_FLOAT))
		TYPE_VECTOR2I: return _set_type(Vector2i.ZERO, str_to_array(s, TYPE_INT))
#		TYPE_RECT2: return "Rect2"
#		TYPE_RECT2I: return "Rect2i"
		TYPE_VECTOR3: return _set_type(Vector3.ZERO, str_to_array(s, TYPE_FLOAT))
		TYPE_VECTOR3I: return _set_type(Vector3i.ZERO, str_to_array(s, TYPE_INT))
#		TYPE_TRANSFORM2D: return "Transform2D"
#		TYPE_PLANE: return "Plane"
#		TYPE_QUATERNION: return "Quaternion"
#		TYPE_AABB: return "AABB"
#		TYPE_BASIS: return "Basis"
#		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_COLOR: return str_to_color(s)
		TYPE_STRING_NAME: return StringName(s)
		TYPE_NODE_PATH: return NodePath(s)
#		TYPE_RID: return "RID"
#		TYPE_OBJECT: return "Object"
#		TYPE_CALLABLE: return "Callable"
#		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return str_to_dict(s)
#		TYPE_ARRAY: return "Array"
#		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
#		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
#		TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
#		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
#		TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
#		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
#		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
#		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
#		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
	
	push_error("Non implemented '%s' String to %s." % [s, UType.get_name_from_type(type)])
	
	return express(s)
