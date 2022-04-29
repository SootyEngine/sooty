@tool
extends Data
class_name PatchableData
func get_class() -> String:
	return "PatchableData"

var _props := {}

func _init(d := {}):
	UObject.set_state(self, d, true, true)
	for k in d:
		if not k in self:
			_props[k] = d[k]
	_post_init.call_deferred()

# along with public properties, include the _extra keys when saving/loading
func _get_state_properties() -> Array:
	return UObject._get_state_properties(self) + _props.keys()

func _get(property: StringName):
	if str(property) in _props:
		return _props[str(property)]

func _set(property: StringName, value) -> bool:
	if str(property) in _props:
		_props[str(property)] = value
		return true
	return false
