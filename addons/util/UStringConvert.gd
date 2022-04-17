@tool
extends RefCounted
class_name UStringConvert

const S2T_DONT_CONVERT := -123_456
const S2T_BUILT_IN := -321_456
const S2T_EXPRESSION = -654_321
const S2T_STR_TO_VAR := -456_123

static func to_type(s: String, type: Variant, object: Object = null, default = null) -> Variant:
	# if string, it's a class_name
	if type is String:
		# is class_name?
		if UClass.exists(type):
			# find a database to grab it from
			var script: Script = UClass.get_class_script(type)
			if script.has_method("_str_to_instance"):
				return script._str_to_instance(s, type)
			else:
				push_error("Can't convert '%s' to '%s'. No static _str_to_instance() methods." % [s, type])
				return null
		
		# is an Enum?
		else:
			if object == null:
				push_error("Can't convert '%' to Enum '%s' without reference to object." % [s, type])
				return -1
			
			var the_enum = object[type]
			return the_enum.values().find(s)
		
#		else:
#			push_error("No manager to convert '%s' to %s." % [s, type])
		return null
	
	elif type is int:
		match type:
			S2T_DONT_CONVERT: return s
			S2T_BUILT_IN: return str2var(s)
			S2T_EXPRESSION: return UString.express(s)
			S2T_STR_TO_VAR: return to_var(s)
			
			TYPE_NIL: return null
			TYPE_BOOL: return s == "true"
			TYPE_INT: return s.replace("_", "").to_int()
			TYPE_FLOAT: return s.replace("_", "").to_float()
			TYPE_STRING: return s
			TYPE_VECTOR2: return _set_type(Vector2.ZERO, to_array(s, TYPE_FLOAT))
			TYPE_VECTOR2I: return _set_type(Vector2i.ZERO, to_array(s, TYPE_INT))
	#		TYPE_RECT2: return "Rect2"
	#		TYPE_RECT2I: return "Rect2i"
			TYPE_VECTOR3: return _set_type(Vector3.ZERO, to_array(s, TYPE_FLOAT))
			TYPE_VECTOR3I: return _set_type(Vector3i.ZERO, to_array(s, TYPE_INT))
	#		TYPE_TRANSFORM2D: return "Transform2D"
	#		TYPE_PLANE: return "Plane"
	#		TYPE_QUATERNION: return "Quaternion"
	#		TYPE_AABB: return "AABB"
	#		TYPE_BASIS: return "Basis"
	#		TYPE_TRANSFORM3D: return "Transform3D"
			TYPE_COLOR: return to_color(s)
			TYPE_STRING_NAME: return StringName(s)
			TYPE_NODE_PATH: return NodePath(s)
	#		TYPE_RID: return "RID"
	#		TYPE_OBJECT: return "Object"
	#		TYPE_CALLABLE: return "Callable"
	#		TYPE_SIGNAL: return "Signal"
			TYPE_DICTIONARY: return to_dict(s)
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
	return null

static func to_var(s: String) -> Variant:
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
static func to_array(s: String, type: int = -1) -> Array:
	return Array(s.split(",")).map(func(x): return to_type(x.strip_edges(), type))

static func to_color(s: String, default: Variant = Color.WHITE) -> Variant:
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
		if UString.is_wrapped(s, "(", ")"):
			s = UString.unwrap(s, "(", ")")
		# floats?
		return _set_type(Color.WHITE, to_array(s, TYPE_FLOAT))
#	push_error("Can't convert '%s' to color." % s)
	return default

static func to_dict(s: String) -> Dictionary:
	if UString.is_wrapped(s, "{", "}"):
		return UString.express(s)
	else:
		var out := {}
		for part in UString.split_outside(s, " "):
			var kv = part.split(":")
			out[kv[0].strip_edges()] = to_var(kv[1].strip_edges())
		return out

static func _set_type(v: Variant, vals: Array) -> Variant:
	for i in len(vals):
		v[i] = vals[i]
	return v

