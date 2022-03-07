@tool
extends Resource
class_name UString

static func find_most_similar(to: String, options: Array, threshold: float = 0.25) -> Array:
	var out := []
	for option in options:
		var sim := to.similarity(option)
		if sim >= threshold:
			out.append([sim, option])
	# sort by similarity
	out.sort_custom(func(a, b): return a[0] > b[0])
	# only return the strings
	return out.map(func(x): return x[1])
