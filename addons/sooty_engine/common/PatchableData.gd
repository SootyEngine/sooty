extends Data
class_name PatchableData

const DEFAULT_FORMAT := "[b]{name}[]"
var _extra := {}

func get_class() -> String:
	return "PatchableDataObject"

func _init(d := {}):
	UObject.set_state(self, d)
	for k in d:
		if not k in self:
			_extra[k] = d[k]
	_post_init.call_deferred()

# along with public properties, include the _extra keys when saving/loading
func _get_state_properties() -> Array:
	return UObject._get_state_properties(self) + _extra.keys()

# add a property from DataParser
func _patch_property(property: String, value: Variant):
	_extra[property] = value

# add an object from DataParser
func _patch_object(property: String, type: String) -> Object:
	_extra[property] = PatchableData.new() if type == "" else UObject.create(type)
	return _extra[property]

# add a list of properties from DataParser
func _patch_list_property(property: String, value: Variant):
	print("ADD %s to %s." % [value, property])
	UDict.append(_extra, property, value)

# add a list of objects from DataParser
func _patch_list_object(property: String, type: String) -> Object:
	var obj: Object = PatchableData.new() if type == "" else UObject.create(type)
	UDict.append(_extra, property, obj)
	return obj

func _get(property: StringName):
	if str(property) in _extra:
		return _extra[str(property)]

func _set(property: StringName, value) -> bool:
	if str(property) in _extra:
		_extra[str(property)] = value
		return true
	return false

func as_string() -> String:
	if "format" in self:
		if self.format == "":
			if Global.config.has_section_key("default_formats", get_class()):
				var fmt = Global.config.get_value("default_formats", get_class(), DEFAULT_FORMAT)
				return fmt.format(UObject.get_state(self))
		else:
			return self.format.format(UObject.get_state(self))
	
	return DEFAULT_FORMAT.format(UObject.get_state(self))
