extends RefCounted
class_name Bool

signal toggled()
signal enabled()
signal disabled()

var set := false

func _get_state():
	return set

func _set_state(patch: Variant):
	if patch is bool:
		set = patch
	else:
		push_error("Can't set Bool to non bool '%'." % [patch])

func _operator_get() -> bool:
	return set

func _operator_set(to: Variant):
	if to is bool and set != to:
		set = to
		toggled.emit()
		if set:
			enabled.emit()
		else:
			disabled.emit()
