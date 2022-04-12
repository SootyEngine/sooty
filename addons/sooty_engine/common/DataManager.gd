extends Resource
class_name DataManager

var _all: Dictionary = {}
var _iter_current := 0

func _init() -> void:
	_post_init.call_deferred()

func _post_init():
	Mods.pre_loaded.connect(func(): _all.clear())

func get_total() -> int:
	return len(_all)

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
	return _all.keys()[_iter_current]

func _get(property: StringName):
	if str(property) in _all:
		return _all[str(property)]

# override this!
func _get_data_class() -> String:
	assert(false)
	return ""

func has(id: String) -> bool:
	return id in _all

func find(id: String, error_action := "find") -> Variant:
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
	_all[key] = UObject.create(type if type else _get_data_class())
	return _all[key]

func _to_string() -> String:
	return UObject._to_string_nice(self)
