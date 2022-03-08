@tool
class_name UList

# works like python list[begin:end]
static func part(a: Array, begin: int = 0, end=null) -> Array:
	if end == null:
		end = len(a)
	elif end < 0:
		end = len(a) - end
	
#	if a is Array:
	return a.slice(begin, end)

static func list(thing: Variant) -> Array:
	return [] if thing == null else thing if thing is Array else [thing]

static func append(target: Array, patch: Variant):
	if patch is Array:
		target.append_array(patch)
	else:
		target.append(patch)

static func nonnull(items: Array) -> Array:
	var out := []
	for item in items:
		if item != null:
			out.append(item)
	return out

static func erase_last(a: Array, item: Variant) -> bool:
	var i = a.find_last(item)
	if i != -1:
		a.remove_at(i)
		return true
	return false

# like the string version, but it works with any array.
static func ends_with(a: Array, b: Array) -> bool:
	var la := len(a)
	var lb := len(b)
	if lb <= la:
		for i in lb:
			if a[la-lb-1+i] != b[i]:
				return false
		return true
	return false
