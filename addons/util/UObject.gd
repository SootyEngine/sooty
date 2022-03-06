@tool
extends Resource
class_name UObject

static func get_class_name(o: Object) -> String:
	return o.get_script().resource_path.get_file().split(".", true, 1)[0]

static func get_state(o: Object) -> Dictionary:
	var out := {}
	for prop in o.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.name[0] != "_":
			match prop.type:
				TYPE_OBJECT:
					out[prop.name] = get_state(o[prop.name])
				TYPE_DICTIONARY:
					out[prop.name] = _get_dict_state(o[prop.name])
				_:
					out[prop.name] = o[prop.name]
	return out

static func _get_dict_state(dict: Dictionary) -> Dictionary:
	var out := {}
	for k in dict:
		match typeof(dict[k]):
			TYPE_OBJECT:
				out[k] = get_state(dict[k])
			TYPE_DICTIONARY:
				out[k] = _get_dict_state(dict[k])
			_:
				out[k] = dict[k]
	return out

static func set_state(o: Object, data: Dictionary):
	for prop in o.get_property_list():
		if prop in data and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.name[0] != "_":
			match prop.type:
				TYPE_OBJECT:
					set_state(o[prop.name], data[prop.name])
				_:
					o[prop.name] = data[prop.name]

static func patch(target: Variant, patch: Dictionary):
	for k in patch:
		if k in target:
			if target[k] is Dictionary:
				patch(target[k], patch[k])
			else:
				target[k] = patch[k]
		
		elif target is Dictionary:
			target[k] = patch[k]
		
		else:
			push_error("Couldn't find '%s' in %s." % [k, target])

# Properly divides an array as arguments for a function. Like python.
static func call_w_args(obj: Object, method: String, args: Array = []) -> Variant:
	if not obj.has_method(method):
		push_error("No method '%s(%s)' in %s." % [method, args, obj])
		return
	
	var arg_info = "_%s_ARGS" % method
	
	if arg_info in obj:
		arg_info = obj[arg_info]
		
		var new_args := []
		
		for k in arg_info:
			if not len(args):
				break
			
			match k:
				"kwargs":
					if args[-1] is Dictionary:
						new_args.append(args.pop_back())
				"args":
					new_args.append(args)
				_:
					new_args.append(args.pop_front())
		
		args = new_args
	
	var got = obj.callv(method, args)
	return got

func type_name(v: Variant) -> String:
	match typeof(v):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		
		TYPE_VECTOR2: return "Vector2"
		TYPE_RECT2: return "Rect2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_TRANSFORM3D: return "Transform2D"
		TYPE_COLOR: return "Color"
		
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		
		TYPE_PACKED_BYTE_ARRAY: return "PoolByteArray"
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

