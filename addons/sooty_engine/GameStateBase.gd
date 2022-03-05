@tool
extends Node
class_name GameStateBase

var _default := {}

func _init():
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.name[0] != "_":
			_default[prop.name] = self[prop.name]
	print(_default)

func _state_reset():
	for key in _default:
		self[key] = _default[key]

func _state_snapshot() -> Dictionary:
	var out := {}
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.name[0] != "_":
			out[prop.name] = self[prop.name]
	return out
