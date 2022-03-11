@tool
extends Resource
class_name UString

# Get a list of strings that are similar, sorted by similarity.
static func find_most_similar(to: String, options: Array, threshold: float = 0.25) -> Array[String]:
	var out := []
	for option in options:
		var sim := to.similarity(option)
		if sim >= threshold:
			out.append([sim, option])
	# sort by similarity
	out.sort_custom(func(a, b): return a[0] > b[0])
	# only return the strings
	return out.map(func(x): return x[1])

# Works like python list[begin:end]
static func part(s: String, from: int = 0, to = null) -> String:
	if to == null:
		to = len(s)
	elif to < 0:
		to = len(s) - to
	return s.substr(from, to-from)

# Removes a string from between tags, and returns [cleaned string, inner string].
static func extract(s: String, head: String, tail: String, strip_edges: bool = true) -> Array[String]:
	var a := s.find(head)
	if a != -1:
		var b := s.find(tail, a+len(head))
		if b != -1:
			var outer := part(s, 0, a).strip_edges(false, strip_edges) + part(s, b+len(tail)).strip_edges(strip_edges, false)
			var inner := part(s, a+len(head), b)
			return [outer, inner]
		else:
			var outer := part(s, 0, a).strip_edges(false, strip_edges)
			var inner :=  part(s, a+len(head))
			return [outer, inner]
	else:
		return [s, ""]

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