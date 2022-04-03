extends "res://addons/sooty_engine/autoloads/base_state.gd"

func _get_subdir() -> String:
	return "states"

func _ready() -> void:
	super._ready()
	Saver._get_state.connect(_save_state)
	Saver._set_state.connect(_load_state)

func _has(property: StringName):
	if Persistent._has(property):
		return true
	return super._has(property)

func _get(property: StringName):
	if Persistent._has(property):
		return Persistent._get(property)
	return super._get(property)

func _set(property: StringName, value) -> bool:
	if Persistent._has(property):
		return Persistent._set(property, value)
	return super._set(property, value)

func get_save_state() -> Dictionary:
	return _get_changed_states()

var _expr := Expression.new()
func _eval(expression: String, default = null) -> Variant:
	# assignments?
	for op in StringAction.OP_ASSIGN:
		if op in expression:
			var p := expression.split(op, true, 1)
			var property := p[0].strip_edges()
			if _has(property):
				var old_val = _get(property)
				var new_val = _eval(p[1].strip_edges())
				match op:
					" = ": _set(property, new_val)
					" += ": _set(property, old_val + new_val)
					" -= ": _set(property, old_val - new_val)
					" *= ": _set(property, old_val * new_val)
					" /= ": _set(property, old_val / new_val)
				return _get(property)
			else:
				push_error("No property '%s' in State." % property)
				return default
	
	# pipes
	if "|" in expression:
		var p := expression.split("|", true, 1)
		var got = _eval(p[0])
		return StringAction._pipe(got, p[1])
	
	var global = StringAction._globalize_functions(expression).strip_edges()
#	prints("(%s) >>> (%s)" %[expression, global])
	
	if _expr.parse(global, []) != OK:
		push_error(_expr.get_error_text() + ": " + expression)
	else:
		var result = _expr.execute([], self, false)
		if _expr.has_execute_failed():
			push_error("_eval(\"%s\") failed: %s." % [global, _expr.get_error_text()])
		else:
			return result
	return default
