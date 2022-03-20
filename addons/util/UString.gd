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

static func replace_between(s: String, head: String, tail: String, call: Callable) -> String:
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
		var got = call.call(index, inner)
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
static func split_on_spaces(s: String) -> Array:
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
