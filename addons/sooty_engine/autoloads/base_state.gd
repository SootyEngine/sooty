extends Node
class_name BaseState

signal changed(property: Array)
signal changed_to(property: Array, to: Variant)
signal changed_from_to(property: Array, from: Variant, to: Variant)

var _silent := false # won't emit signals when changing things.
var _changed := false # state has changed.
var _default := {}
var _children := []

func _get_subdir() -> String:
	assert(false)
	return ""

func _save_state(data: Dictionary):
	data[_get_subdir()] = _get_changed_states()

func _load_state(data: Dictionary):
	_silent = true
	_reset()
	UObject.set_state(self, data.get(_get_subdir(), {}))
	_silent = false

func _ready() -> void:
	child_entered_tree.connect(_child_added)
	Mods.pre_loaded.connect(_clear_mods)
	Mods.load_all.connect(_load_mods)
	Mods.loaded.connect(_loaded_mods)

func _clear_mods():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _load_mods(mods: Array):
	var subdir := _get_subdir()
	
	# init nodes from .gd scripts.
	for mod in mods:
		mod.meta[subdir] = []
		
		var head = mod.dir.plus_file(subdir)
		for script_path in UFile.get_files(head, ".gd"):
			var state = load(script_path).new()
			if state is Node:
				mod.meta[subdir].append(script_path) # tell Mods what file has been installed
				state.set_name(UFile.get_file_name(script_path))
				add_child(state)
			else:
				# TODO: Allow resources.
				push_error("States must be node. Can't load %s." % script_path)
	
	# install .data
	for mod in mods:
		var head = mod.dir.plus_file(subdir)
		for data_path in UFile.get_files(head, Soot.EXT_DATA):
			mod.meta[subdir].append(data_path) # tell Mods what file has been installed
			var state = DataParser.new().parse(data_path)
			UObject.patch(self, state, [data_path])

func _loaded_mods():
	print("DEFAULT STAE FOR %s." % _get_subdir())
	_default = _get_state()

func _reset():
	UObject.set_state(self, _default)

func _child_added(_n: Node):
	_children = get_children()

func _has_method(method: String) -> bool:
	for node in _children:
		if node.has_method(method):
			return true
	return false

func _get_method_parent(method: String) -> String:
	for node in _children:
		if node.has_method(method):
			return node.name
	return ""

func _call(method: String, args: Array = [], default = null) -> Variant:
	if "." in method:
		var p := method.rsplit(".", true, 1)
		method = p[1]
		if p[0] == "scene":
			return UObject.call_w_args(get_tree().current_scene, method, args)
		elif _has(p[0]):
			var target = _get(p[0])
			return UObject.call_w_args(target, method, args)
		else:
			push_error("No property '%s' in state." % p[0])
			return default
	
	# first check if it's a property
	if len(args) == 0:
		for node in _children:
			if method in node:
				return node[method]
	
	# call the first method we find
	for node in _children:
		if node.has_method(method):
			return UObject.call_w_args(node, method, args)
	
	return default

func _reset_state():
	UObject.set_state(self, _default)

func _get_changed_states() -> Dictionary:
	var current := _get_state()
	return UDict.get_different(_default, current)

func _get_state() -> Dictionary:
	var out := {}
	for child in _children:
		UDict.merge(out, UObject.get_state(child), true)
	return out

func _has(property: StringName) -> bool:
	var path := str(property).split(".")
	property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null and property in o:
			return true
	return false

func _get(property: StringName):
	var path := str(property).split(".")
	property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null:
			if property in o:
				return o[property]

func _set(property_path: StringName, value) -> bool:
	var path := str(property_path).split(".")
	var property := path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null and property in o:
			var old = o.get(property)
			if typeof(value) != typeof(old):
				push_error("Can't set %s (%s) to %s (%s)." % [property, UObject.get_name_from_type(typeof(old)), value, UObject.get_name_from_type(typeof(value))])
				return true
			o.set(property, value)
			var new = o.get(property)
			if old != new:
				if not _silent:
					_changed = true
					changed.emit(path)
					changed_to.emit(path, new)
					changed_from_to.emit(path, old, new)
			return true
	push_error("No %s in %s. (Attempted '%s = %s')" % [property_path, _get_state(), property, value])
	return true

func _get_all_of_type(type: Variant) -> Dictionary:
	var out := {}
	for k in _default:
		var v = _get(k)
		if v is type:
			out[k] = v
	return out

func _get_all_of_class(classname: String) -> Dictionary:
	var out := {}
	for k in _default:
		var v = _get(k)
		if v is Object and v.get_class() == classname:
			out[k] = v
	return out

func _has_of_type(id: String, type: Variant) -> bool:
	return id in _default and self[id] is type
