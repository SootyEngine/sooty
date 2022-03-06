@tool
extends Node
class_name GameStateBase

signal changed(key: String)
signal changed_from_to(key: String, from: Variant, to: Variant)

var _default := {}

func _init():
	_default = UObject.get_state(self)
#	print("INITIAL STATE", _default)
#	print(_get_properties_of_class("Quest"))
	_post_init.call_deferred()

func _post_init():
	pass

func _set(property: StringName, value) -> bool:
	if property in self:
		var old = self[property]
		if old != value:
			self[property] = value
			changed.emit(property)
			changed_from_to.emit(property, old, value)
		return true
	return false

func _reset_state():
	UObject.set_state(self, _default)

func _load_state(state: Dictionary):
	_reset_state()
	UObject.set_state(self, state)

func _get_changed_states() -> Dictionary:
	var current := UObject.get_state(self)
	return UDict.get_different(_default, current)

# Collect all properties that extend the type of class.
# Good for collecting similar types, like Quests, Characters, without needing them to all call a register.
func _get_properties_of_class(cname: String) -> Dictionary:
	var out := {}
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.type == TYPE_OBJECT:
			var v = self[prop.name]
			if UObject.get_class_name(v) == cname:
				out[prop.name] = v
	return out
