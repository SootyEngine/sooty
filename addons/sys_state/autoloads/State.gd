extends "res://addons/sooty_engine/autoloads/base_state.gd"

var _calls := {}
var _expr := Expression.new()

func _post_init():
	# collect state functions in a dict, so all can access them.
	for child in _children:
		for m in child.get_method_list():
			var n: String = m.name
			if n[0] != "_" and not has_method(m.name):
				_calls[n] = child[n]
	super._post_init()

func _call(call: String):
	var args := Sooty.str_to_args(call)
	var fname = args.pop_front()
	# call group node function
	if "." in fname:
		var p = fname.split(".", true, 1)
		Global.call_group_flags(SceneTree.GROUP_CALL_REALTIME, p[0], p[1], args)
	# call shortcut
	elif fname in _calls:
		return UObject.callablev(_calls[fname], args)
	# call scene function
	elif get_tree().current_scene.has_method(fname):
		return get_tree().current_scene.callv(fname, args)
	# alert user nothing happened
	else:
		push_error("No function %s(%s) in State." % [fname, args])

func _eval(expression: String, default = null) -> Variant:
	if "|" in expression:
		var p := expression.split("|", true, 1)
		var got = _eval(p[0])
		return _pipe(got, p[1])
	
	if _expr.parse(expression, []) != OK:
		push_error(_expr.get_error_text())
	else:
		var result = _expr.execute([], State, false)
		if _expr.has_execute_failed():
			push_error("_eval(\"%s\") failed: %s." % [expression, _expr.get_error_text()])
		else:
			return result
	return default

func _test(expression: String) -> bool:
	return true if _eval(expression) else false

func _pipe(value: Variant, pipes: String) -> Variant:
	for pipe in pipes.split("|"):
		var args = UString.split_on_spaces(pipe)
		var fname = args.pop_front()
		if fname in _call:
			value = UObject.callablev(_calls[fname], [value] + args.map(_eval))
		else:
			push_error("Can't pipe %s. No %s." % [value, fname])
	return value

func _has(property: StringName):
	if Persistent._has(property):
		return true
	return super._has(property)

func _get(property: StringName):
	if Persistent._has(property):
		return Persistent._get(property)
	match str(property):
		"current_scene": return get_tree().current_scene
	return super._get(property)

func _set(property: StringName, value) -> bool:
	if Persistent._has(property):
		return Persistent._set(property, value)
	return super._set(property, value)

func _ready() -> void:
	super._ready()
	print("[States]")
	for script_path in UFile.get_files("res://states", ".gd"):
		var mod = install(script_path)
		print("\t- ", script_path)

func get_save_state() -> Dictionary:
	return _get_changed_states()
