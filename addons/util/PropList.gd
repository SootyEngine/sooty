@tool
extends RefCounted
class_name PropList
# Random tools for _get_property_list()

# example:
# func _get_property_list() -> Array:
# 	return PropList.new(self)\
#		.category("My Properties")\
#			.prop("variable")\
#			.prop("var_2")\
#			.prop_enum("venum", ["option 1", "option 2"])\
# 		.done()

static func to_list(obj: Object, d: Dictionary) -> Array:
	var out := []
	for category_name in d:
		out.append({
			name=category_name,
			type=TYPE_NIL,
			usage=PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE 
		})
		for property_name in d[category_name]:
			var prop = d[category_name][property_name]
			var type = prop.type if "type" in prop else typeof(obj[prop])
			out.append({
				name=property_name,
				type=type
			})
	return out

var list := []
var this: Object

func _init(t: Object = null):
	this = t

func category(name: String) -> PropList:
	list.append({
		name=name,
		type=TYPE_NIL,
		usage=PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	return self

func prop(name: String, type: int = -1) -> PropList:
	if type == -1 and this:
		type = typeof(this[name])
	
	list.append({
		name=name,
		type=type
	})
	
	return self

func prop_enum(name: String, options: Array, type: int = -1) -> PropList:
	if type == -1 and this:
		type == typeof(this[name])
	
	list.append({
		name=name,
		type=type,
		hint=PROPERTY_HINT_ENUM,
		hint_string=",".join(PackedStringArray(options))
	})
	
	return self

func done() -> Array:
	return list
