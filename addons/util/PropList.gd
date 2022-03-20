extends Resource
class_name PropList

var list := []

func category(name: String) -> PropList:
	list.append({
		name=name,
		type=TYPE_NIL,
		usage=PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	return self

func prop(name: String, type: int) -> PropList:
	list.append({
		name=name,
		type=type
	})
	return self

func prop_enum(name: String, type: int, options: Array) -> PropList:
	list.append({
		name=name,
		type=type,
		hint=PROPERTY_HINT_ENUM,
		hint_string=",".join(PackedStringArray(options))
	})
	return self

func done() -> Array:
	return list
