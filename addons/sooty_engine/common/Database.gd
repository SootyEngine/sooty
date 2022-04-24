@tool
extends RefCounted
class_name Database, "res://addons/soot_engine/icons/database.png"
func get_class():
	return "Database"

var _all: Dictionary = {}
var _iter_current := 0
var _data_class_name: String = "Data"

func _init(type: Script, d := {}) -> void:
	_data_class_name = UClass.get_class_name(type)
	DataManager.register(_data_class_name, self)
	_post_init.call_deferred()
	
	for k in d:
		if d[k] is Dictionary:
			_all[k] = UClass.create(_data_class_name, [d[k]])
		else:
			_all[k] = d[k]

func _post_init():
	pass

# look for this items id
func _get_id(data: Variant) -> String:
	for k in _all:
		if _all[k] == data:
			return k
	return ""

func get_all_ids() -> Array:
	return _all.keys()

func get_all() -> Array:
	return _all.values()

func get_many(ids: Array) -> Array:
	return ids.map(get)

func get_total() -> int:
	return len(_all)

func _get_state_properties() -> Array:
	return _all.keys()

func _get_state():
	return UObject.get_state(_all)

func _set_state(state: Dictionary):
	UObject.set_state(_all, state)

func _iter_init(arg) -> bool:
	_iter_current = 0
	return _iter_current < len(_all)

func _iter_next(arg) -> bool:
	_iter_current += 1
	return _iter_current < len(_all)

func _iter_get(arg):
	return _all.values()[_iter_current]

func _get(property: StringName):
	if str(property) in _all:
		return _all[str(property)]

func has(id: String) -> bool:
	return id in _all

func find(id: String, error_action := "find") -> Variant:
	if len(_all) == 0:
		push_error("Can't %s %s. No %s defined." % [error_action, id, _data_class_name])
		return null
	elif has(id):
		return _all[id]
	else:
		# show user a list of similar items
		UString.push_error_similar("Can't %s %s named %s." % [error_action, _data_class_name, id], id, _all.keys())
		return null

func _patch_object(key: String, type: String) -> Object:
	_all[key] = UClass.create(type if type else _data_class_name)
	return _all[key]

func _to_string() -> String:
	return UClass._to_string2(self)
