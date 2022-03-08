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
