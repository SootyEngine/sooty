@tool
extends Resource
class_name UDict

static func log(d: Variant, msg: String = ""):
	print(msg, JSON.new().stringify(d, "\t", false))

static func first(d: Dictionary, default: Variant = null) -> Variant:
	return default if not len(d) else d.values()[0]

static func recycle(target: Dictionary, patch: Dictionary) -> Dictionary:
	target.clear()
	merge(target, patch)
	return target

static func erase_many(target: Dictionary, keys: Array):
	for k in keys:
		var _e = target.erase(k)

# get the difference of all values
static func get_difference(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := {}
	for k in a:
		if k in b:
			out[k] = a[k] - b[k]
		else:
			out[k] = a[k]
	for k in b:
		if not k in a:
			out[k] = b[k]
	return out

# do both have same length and values?
static func is_same(a:Dictionary, b:Dictionary) -> bool:
	if len(a) != len(b):
		return false
	
	for k in a:
		if not k in b or a[k] != b[k]:
			return false
	
	for k in b:
		if not k in a or b[k] != a[k]:
			return false
	
	return true

static func append(d:Dictionary, k, v):
	if not k in d:
		d[k] = [v]
	else:
		d[k].append(v)

static func count(d:Dictionary, k, v):
	if not k in d:
		d[k] = v
	else:
		d[k] += v

static func merge_missing(target: Dictionary, patch: Dictionary):
	for k in patch:
		if not k in target:
			target[k] = patch[k]

static func merge(target: Dictionary, patch: Dictionary, deep: bool = false, lists:bool = false, append: bool = false):
	if not deep:
		for k in patch:
			target[k] = patch[k]
	
	else:
		for k in patch:
			if not k in target:
				target[k] = patch[k]
			
			else:
				if target[k] is Dictionary:
					merge(target[k], patch[k], deep, lists)
				
				elif target[k] is Array and lists:
					if patch[k] is Array:
						target[k].append_array(patch[k])
					else:
						target[k].append(patch[k])
				
				# append if the same type
				elif typeof(target[k]) == typeof(patch[k]):
					if append and target[k] != patch[k]:
						target[k] = [target[k], patch[k]]
					else:
						target[k] = patch[k]
				
				# replace different type
				else:
					push_error("can't merge %s with %s. replacing %s instead." % [Global.type_name(target[k]), Global.type_name(patch[k]), k])
					target[k] = patch[k]

static func set_at(target: Dictionary, path: Array, value: Variant):
	var t = target
	for i in len(path)-1:
		var part = path[i]
		if not part in t:
			t[part] = {}
		t = t[part]
	t[path[-1]] = value

static func merge_at(target: Dictionary, path: Array, patch: Dictionary, deep: bool = false, lists: bool = false):
	var t = target
	for i in len(path):
		var part = path[i]
		if not part in t:
			t[part] = {}
		t = t[part]
	merge(t, patch, deep, lists)

static func flip_keys_and_values(d:Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[d[k]] = k
	return out

static func new_ticker(from: Dictionary, initial: int = 0) -> Dictionary:
	var out := {}
	for item in from:
		out[item] = initial
	return out

static func tick(d: Dictionary, key, amount: int = 1, remove_if_empty: bool = true) -> int:
	if not key in d:
		d[key] = amount
	else:
		d[key] += amount
	if remove_if_empty and d[key] == 0:
		d.erase(key)
		return 0
	return d[key]

static func total(d: Dictionary) -> Variant:
	if not len(d):
		return null
	var v := d.values()
	var out = v[0]
	for i in range(1, len(v)):
		out += v[i]
	return out

#class DSorter:
#	var items:Array = []
#	var dict:Dictionary
#
#	func _init(d:Dictionary):
#		dict = d
#
#	func sort_by_key(reversed:bool=false):
#		for k in dict:
#			items.append([len(k) if k is String else k, k, dict[k]])
#		return _out(reversed)
#
#	func sort_by_value_key(key, reversed:bool=false):
#		for k in dict:
#			items.append([dict[k].get(key, 0), k, dict[k]])
#		return _out(reversed)
#
#	func _out(reversed:bool):
#		if reversed:
#			items.sort_custom(self, "_sort_dict")
#		else:
#			items.sort_custom(self, "_sort")
#
#		dict.clear()
#		for item in items:
#			dict[item[1]] = item[2]
#
#		return dict
#
#	func _sort(a, b): return a[0] < b[0]
#	func _sort_reversed(a, b): return a[0] > b[0]

# godot preserves dict order, so this can work
static func _to_args(d: Dictionary) -> Array:
	var out := []
	for k in d:
		out.append([k, d[k]])
	return out

static func _from_args(d: Dictionary, a: Array) -> Dictionary:
	d.clear()
	for item in a:
		d[item[0]] = item[1]
	return d

# sort a dictionary by it's keys
static func sort_by_key(d: Dictionary, reversed: bool = false):
	var a := _to_args(d)
	if reversed:
		a.sort_custom(func(x, y): return x[0] >= y[0])
	else:
		a.sort_custom(func(x, y): return x[0] < y[0])
	return _from_args(d, a)

static func sort_by_value(d: Dictionary, reversed: bool = false):
	var a := _to_args(d)
	if reversed:
		a.sort_custom(func(x, y): return x[1] >= y[1])
	else:
		a.sort_custom(func(x, y): return x[1] < y[1])
	return _from_args(d, a)

# determine which keys are different or new
static func get_different(default: Dictionary, current: Dictionary) -> Dictionary:
	var out := {}
	for k in current:
		if not k in default:
			out[k] = current[k]
		elif default[k] != current[k]:
			if current[k] is Dictionary and default[k] is Dictionary:
				var d = get_different(default[k], current[k])
				if d:
					out[k] = d
			else:
				out[k] = current[k]
	return out

static func key_index(d: Dictionary, item) -> int:
	return d.keys().find(item)

static func value_index(d:Dictionary, item) -> int:
	return d.values().find(item)

# calls a function on every dict
static func dig(d: Dictionary, call: Callable, reverse: bool = false):
#	if d is Dictionary:
	if reverse:
		call.call(d)
	
	for k in d:
		dig(d[k], call, reverse)
	
	if not reverse:
		call.call(d)
	
#	elif d is Array:
#		for i in len(d):
#			dig(d[i], call, reverse)
#
#	elif d is Node:
#		call.call(d)
#		for i in d.get_child_count():
#			dig(d.get_child(i), call, reverse)
	
	else:
		push_error("not implemented")
#
#static func dig_replace(d: Dictionary, call: Callable):
#	for k in d:
#		dig_replace(d[k], call)
#	return call.call(d)

