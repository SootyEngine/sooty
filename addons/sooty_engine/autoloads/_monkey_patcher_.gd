@tool
extends RefCounted
# a state for holding data that's added at runtime through base_state and .soda files.

var _data := {}

func _get(property: StringName):
	return _data.get(property)

func _set(property: StringName, value) -> bool:
	if property in _data:
		_data[property] = value
		return true
	return false

func _get_state():
	return UObject.get_state(_data)
