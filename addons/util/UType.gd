@tool
extends RefCounted
class_name UType

static func same_type(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b)

static func same_type_and_value(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b

static func get_type_name(o: Variant) -> String:
	return get_name_from_type(typeof(o))

static func print_types(list: Array):
	var out := []
	for item in list:
		out.append("%s (%s)" % [item, get_type_name(item)])
	print(", ".join(out))

static func get_type_from_name(name: String) -> int:
	match name:
		"null": return TYPE_NIL
		"bool": return TYPE_BOOL
		"int": return TYPE_INT
		"float": return TYPE_FLOAT
		"String": return TYPE_STRING
		"Vector2": return TYPE_VECTOR2
		"Vector2i": return TYPE_VECTOR2I
		"Rect2": return TYPE_RECT2
		"Rect2i": return TYPE_RECT2I
		"Vector3": return TYPE_VECTOR3
		"Vector3i": return TYPE_VECTOR3I
		"Transform2D": return TYPE_TRANSFORM2D
		"Plane": return TYPE_PLANE
		"Quaternion": return TYPE_QUATERNION
		"AABB": return TYPE_AABB
		"Basis": return TYPE_BASIS
		"Transform3D": return TYPE_TRANSFORM3D
		"Color": return TYPE_COLOR
		"StringName": return TYPE_STRING_NAME
		"NodePath": return TYPE_NODE_PATH
		"RID": return TYPE_RID
		"Object":
			# TODO: Use UClass to get actual class_name
			return TYPE_OBJECT
		"Callable": return TYPE_CALLABLE
		"Signal": return TYPE_SIGNAL
		"Dictionary": return TYPE_DICTIONARY
		"Array": return TYPE_ARRAY
		"PackedByteArray": return TYPE_PACKED_BYTE_ARRAY
		"PackedInt32Array": return TYPE_PACKED_INT32_ARRAY
		"PackedInt64Array": return TYPE_PACKED_INT64_ARRAY
		"PackedFloat32Array": return TYPE_PACKED_FLOAT32_ARRAY
		"PackedFloat64Array": return TYPE_PACKED_FLOAT64_ARRAY
		"PackedStringArray": return TYPE_PACKED_STRING_ARRAY
		"PackedVector2Array": return TYPE_PACKED_VECTOR2_ARRAY
		"PackedVector3Array": return TYPE_PACKED_VECTOR3_ARRAY
		"PackedColorArray": return TYPE_PACKED_COLOR_ARRAY
		_: return TYPE_NIL

static func get_name_from_type(type: Variant) -> String:
	# class name?
	if type is String:
		return type
	match type:
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_COLOR: return "Color"
		TYPE_STRING_NAME: return "StringName"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		TYPE_CALLABLE: return "Callable"
		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
		_: return "???"

static func get_default(type: Variant) -> Variant:
	# class_name
	if type is String:
		return null
	match type:
		TYPE_NIL: return null
		TYPE_BOOL: return false
		TYPE_INT: return 0
		TYPE_FLOAT: return 0.0
		TYPE_STRING: return ""
		TYPE_VECTOR2: return Vector2()
		TYPE_VECTOR2I: return Vector2i()
		TYPE_RECT2: return Rect2()
		TYPE_RECT2I: return Rect2i()
		TYPE_VECTOR3: return Vector3()
		TYPE_VECTOR3I: return Vector3i()
		TYPE_TRANSFORM2D: return Transform2D()
		TYPE_PLANE: return Plane()
		TYPE_QUATERNION: return Quaternion()
		TYPE_AABB: return AABB()
		TYPE_BASIS: return Basis()
		TYPE_TRANSFORM3D: return Transform3D()
		TYPE_COLOR: return Color()
#		TYPE_STRING_NAME: return "StringName"
#		TYPE_NODE_PATH: return "NodePath"
#		TYPE_RID: return "RID"
#		TYPE_OBJECT: return "Object"
#		TYPE_CALLABLE: return "Callable"
#		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return {}
		TYPE_ARRAY: return []
		TYPE_PACKED_BYTE_ARRAY: return PackedByteArray()
		TYPE_PACKED_INT32_ARRAY: return PackedInt32Array()
		TYPE_PACKED_INT64_ARRAY: return PackedInt64Array()
		TYPE_PACKED_FLOAT32_ARRAY: return PackedFloat32Array()
		TYPE_PACKED_FLOAT64_ARRAY: return PackedFloat64Array()
		TYPE_PACKED_STRING_ARRAY: return PackedStringArray()
		TYPE_PACKED_VECTOR2_ARRAY: return PackedVector2Array()
		TYPE_PACKED_VECTOR3_ARRAY: return PackedVector3Array()
		TYPE_PACKED_COLOR_ARRAY: return PackedColorArray()
		_: return push_error("No default type for %s." % [get_type_name(type)])
