extends Node
class_name BaseState

signal changed(key: String)
signal changed_from_to(key: String, from: Variant, to: Variant)
signal state_loaded()

var _default := {}
var _children := []

func _ready() -> void:
	child_entered_tree.connect(_child_added)
	_post_init.call_deferred()

func install(path: String):
	var mod: Node = load(path).new()
	mod.set_name(path.get_file().split(".", true, 1)[0])
	add_child(mod)
	return mod

func _post_init():
	_default = _get_state()
#	UDict.log(_default)
	state_loaded.emit()

func _child_added(_n: Node):
	_children = get_children()

func _reset_state():
	UObject.set_state(self, _default)

func _load_state(state: Dictionary):
	_reset_state()
	UObject.set_state(self, state)

func _get_changed_states() -> Dictionary:
	var current := _get_state()# UObject.get_state(self)
	return UDict.get_different(_default, current)

func _set_state(state: Dictionary):
	_reset_state()
	UObject.patch(self, state)

func _get_state() -> Dictionary:
	var out := {}
	for child in _children:
		UDict.merge(out, UObject.get_state(child), true)
	return out

func has(property: StringName) -> bool:
	var path := str(property).split(".")
	property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null and property in o:
			return true
	return false

func _get_objects_property(obj: Object) -> String:
	for k in _default:
		var o = self[k]
		if o is Object and o == obj:
			return k
	return ""

func _get(property: StringName):
	var path := str(property).split(".")
	property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null:
			if property in o:
				return o[property]
			else:
				push_error("No %s in %s" % [property, o])

func _set(property: StringName, value) -> bool:
	var path := str(property).split(".")
	property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if property in o:
			var old = o[property]
			if typeof(value) != typeof(old):
				push_error("Can't set $%s (%s) to %s (%s)." % [property, UObject.get_name_from_type(typeof(old)), value, UObject.get_name_from_type(typeof(value))])
				return true
			o[property] = value
			var new = o[property]
			if old != new:
				changed.emit(property)
				changed_from_to.emit(property, old, new)
				print("Changed %s to %s from %s." % [property, new, old])
			return true
	push_error("No property '%s' in State. (Attempted '%s = %s')" % [property, property, value])
	return true

func _get_all_of_type(type: Variant) -> Dictionary:
	var out := {}
	for k in _default:
		var v = self[k]
		if v is type:
			out[k] = v
	return out

func _has_of_type(id: String, type: Variant) -> bool:
	return id in _default and self[id] is type
