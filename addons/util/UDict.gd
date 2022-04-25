@tool
extends RefCounted
class_name UDict

# debug pretty print
static func log(d: Variant, msg: String = ""):
	print(msg, JSON.new().stringify(d, "\t", false))

static func first(d: Dictionary, default = null) -> Variant:
	return default if not len(d) else d.values()[0]

# copy content of one dict to another
# why? target may be refrenced somewhere, and creating a new one would lose the reference.
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

static func count(d: Dictionary, k, v):
	if not k in d:
		d[k] = v
	else:
		d[k] += v

static func map_list(array: Variant, call: Callable, as_properties := false) -> Dictionary:
	var out := {}
	if as_properties:
		for item in array:
			out[item] = call.call(item)
	else:
		for item in array:
			out[call.call(item)] = item
	return out

static func map_keys(d: Dictionary, call: Callable) -> Dictionary:
	var out := {}
	for k in d:
		out[call.call(k)] = d[k]
	return out

static func map_values(d: Dictionary, call: Callable):
	var out := {}
	for k in d:
		out[k] = call.call(d[k])
	return out

static func merge_missing(target: Dictionary, patch: Dictionary):
	for k in patch:
		if not k in target:
			target[k] = patch[k]

static func merge(target: Dictionary, patch: Dictionary, deep: bool = false, kwargs := {}):
	
	if not deep:
		for k in patch:
			target[k] = patch[k]
	
	else:
		# merge arrays?
		var lists: bool = kwargs.get("lists", false)
		# convert to array if item exists?
		var append: bool = kwargs.get("append", false)
		# replace existing keys?
		var replace: bool = kwargs.get("replace", false)
		
		for k in patch:
			if not k in target:
				target[k] = patch[k]
			
			else:
				if target[k] is Dictionary:
					merge(target[k], patch[k], deep, kwargs)
				
				elif target[k] is Array and lists:
					if patch[k] is Array:
						target[k].append_array(patch[k])
					else:
						target[k].append(patch[k])
				
				# append if the same type
				elif typeof(target[k]) == typeof(patch[k]):
					if append and target[k] != patch[k]:
						target[k] = [target[k], patch[k]]
					elif replace:
						target[k] = patch[k]
					else:
						push_error("Can't replace %s." % [target[k]])
				
				# replace different type
				elif replace:
#					push_error("Can't merge %s with %s. replacing %s instead." % [UType.get_type_name(target[k]), UType.get_type_name(patch[k]), k])
					target[k] = patch[k]
				
				else:
					push_error("Can't replace %s." % [target[k]])

static func merge_at(target: Dictionary, path: Array, patch: Dictionary, deep: bool = false, kwargs := {}):
	var t = target
	for i in len(path):
		var part = path[i]
		if not part in t:
			t[part] = {}
		t = t[part]
	merge(t, patch, deep, kwargs)

static func flip_keys_and_values(d:Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[d[k]] = k
	return out

# tickers keep count of things
static func new_ticker(from: Dictionary, initial: int = 0) -> Dictionary:
	return map(from, func(x): return initial)

static func tick(d: Dictionary, key, amount: int = 1, remove_if_empty: bool = true) -> int:
	if key in d:
		d[key] += amount
	else:
		d[key] = amount
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

static func get_at(d: Dictionary, path: Array, default: Variant = null) -> Variant:
	var out = d
	for i in len(path):
		if path[i] in out:
			out = out[path[i]]
		else:
			return default
	return out

static func set_at(d: Dictionary, path: Array, value: Variant, create := true) -> bool:
	var dict = get_penultimate(d, path, create)
	if dict is Dictionary:
		dict[path[-1]] = value
		return true
	push_error(dict)
	return false

static func get_penultimate(d: Dictionary, path: Array, create := false, default: Variant = null) -> Variant:
	var out = d
	for i in len(path)-1:
		if not path[i] in out:
			if create:
				out[path[i]] = {}
			else:
				push_error("No %s." % path)
				return default
		out = out[path[i]]
	return out

# return a copy that only contains values that are different
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
static func dig(d: Variant, call: Callable, reverse: bool = false):
	match typeof(d):
		TYPE_DICTIONARY:
			if reverse:
				call.call(d)
			
			for k in d:
				dig(d[k], call, reverse)
			
			if not reverse:
				call.call(d)
		
		TYPE_ARRAY:
			for item in d:
				dig(item, call, reverse)

# returns an tree where all vlaues that were empty (str="" int=0 list=[] dict={}) were removed
static func trim_empty(v: Variant):
	var out = v.duplicate(true)
	dig(out,
		func(x):
			for k in x.keys():
				if x[k]:
					pass
				else:
					x.erase(k))
	return out

static func map(d: Dictionary, call: Callable) -> Dictionary:
	var out := {}
	for k in d:
		d[k] = call.call(d[k])
	return out

static func filter(d: Dictionary, call: Callable) -> Dictionary:
	var out := {}
	for k in d:
		if call.call(d[k]):
			out[k] = d[k]
	return out 
