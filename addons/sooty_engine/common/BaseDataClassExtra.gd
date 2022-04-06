extends BaseDataClass
class_name BaseDataClassExtendable

const DEFAULT_FORMAT := "[b]{name}[]"
var _extra := {}

func _init(d := {}):
	UObject.set_state(self, d)
	for k in d:
		if not k in self:
			_extra[k] = d[k]
	_post_init.call_deferred()

# along with public properties, include the _extra keys when saving/loading
func _get_state_properties() -> Array:
	return UObject._get_state_properties(self) + _extra.keys()

# called by UObject, typically.
func _add_property(property: String, value: Variant):
	print("ADD PROPERTY %s=%s to %s" % [property, value, self])
	_extra[property] = value

# called by UObject, typically.
func _add_object(property: String, type: String) -> Object:
	_extra[property] = UObject.create(type)
	return _extra[property]

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
