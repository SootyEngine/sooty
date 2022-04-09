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

static func all_items_of_type(list: Array, type: int) -> bool:
	for i in len(list):
		if typeof(list[i]) != type:
			return false
	return true

static func list(thing: Variant) -> Array:
	match typeof(thing):
		TYPE_NIL: return []
		TYPE_ARRAY: return thing
		TYPE_PACKED_BYTE_ARRAY: return thing
		TYPE_PACKED_INT32_ARRAY: return thing
		TYPE_PACKED_INT64_ARRAY: return thing
		TYPE_PACKED_FLOAT32_ARRAY: return thing
		TYPE_PACKED_FLOAT64_ARRAY: return thing
		TYPE_PACKED_STRING_ARRAY: return thing
		TYPE_PACKED_VECTOR2_ARRAY: return thing
		TYPE_PACKED_VECTOR3_ARRAY: return thing
		TYPE_PACKED_COLOR_ARRAY: return thing
		_: return [thing]

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
