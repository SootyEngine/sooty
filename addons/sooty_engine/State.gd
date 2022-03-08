extends Node

signal changed(key: String)
signal changed_from_to(key: String, from: Variant, to: Variant)

var _default := {}
var _mods := [load("res://state.gd").new()]

func _init():
#	print("INITIAL STATE", _default)
#	print(_get_properties_of_class("Quest"))
	_post_init.call_deferred()

func _post_init():
	_default = _get_state()
	print(JSON.new().stringify(_default, "\t", false))

func _get(property: StringName):
	for m in _mods:
		if property in m:
			return m[property]

func _set(property: StringName, value) -> bool:
	for m in _mods:
		if property in m:
			var old = m[property]
			m[property] = value
			var new = m[property]
			if old != new:
				changed.emit(property)
				changed_from_to.emit(property, old, new)
				print("Changed %s to %s from %s." % [property, new, old])
			return true
	push_error("No property '%s' in State. (Attempted '%s = %s')" % [property, property, value])
	return true

func _reset_state():
	UObject.set_state(self, _default)

func _load_state(state: Dictionary):
	_reset_state()
	UObject.set_state(self, state)

func _get_state() -> Dictionary:
	var out := {}
	for mod in _mods:
		UDict.merge(out, UObject.get_state(mod), true)
	return out

func _set_state(state: Dictionary):
	_reset_state()
	UObject.patch(self, state)

func _get_changed_states() -> Dictionary:
	var current := _get_state()# UObject.get_state(self)
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
