@tool
extends RefCounted
class_name Database, "res://addons/soot_engine/icons/database.png"
func _get_class():
	return "Database"

var _all: Dictionary = {}
var _iter_current := 0

static func get_database(item_or_database: Variant) -> Database:
	if item_or_database is Script:
		item_or_database = UClass.get_class_name(item_or_database)
	
	# use string name to find instance
	if "databases" in Global.meta and item_or_database in Global.meta.databases:
		var m_instance_id: int = Global.meta.databases[item_or_database]
		return instance_from_id(m_instance_id)
	
	push_error("Can't find database for %s." % item_or_database)
	return null

func _init(d := {}) -> void:
	_post_init.call_deferred()
	
	# since all objects share a script, they can access it's meta data
	# which means they can access this database, wherever it is
	# so long as we have the _empt object, the script is in memory.
	var my_class_name := UClass.get_class_name(self)
	var my_data_class := my_class_name.trim_suffix("Database")
#	prints("Manager: %s %s." % [my_class_name, my_data_class])
	if not "databases" in Global.meta:
		Global.meta.databases = {}
	Global.meta.databases[my_class_name] = get_instance_id()
	Global.meta.databases[my_data_class] = get_instance_id()
	
	for k in d:
		if d[k] is Dictionary:
			_all[k] = UClass.create(_get_data_class(), [d[k]])
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

# override this!
func _get_data_class() -> String:
#	push_warning("You should override this instead.")
	return UClass.get_class_name(self).trim_suffix("Database")

func has(id: String) -> bool:
	return id in _all

func find(id: String, error_action := "find"):
	if len(_all) == 0:
		push_error("Can't %s %s. No %s defined." % [error_action, id, _get_data_class()])
		return null
	elif has(id):
		return _all[id]
	else:
		# show user a list of similar items
		UString.push_error_similar("Can't %s %s named %s." % [error_action, _get_data_class(), id], id, _all.keys())
		return null

func _patch_object(key: String, type: String) -> Object:
	prints("Add object: ", UClass.get_class_name(self), key, type)
	_all[key] = UClass.create(type if type else _get_data_class())
	return _all[key]

func _to_string() -> String:
	return UClass._to_string2(self)
