@tool
extends Node
class_name BaseState

signal changed(property: Array)
signal changed_to(property: Array, to: Variant)
signal changed_from_to(property: Array, from: Variant, to: Variant)

# won't emit signals when changing things.
var _silent := false
# state has changed.
var _changed := false
# shorter keys to nested data. (ie: p = characters:player)
var _shortcuts := {}
# the default state, after all mods were installed.
var _default := {}
# all the child nodes
var _children := []
# a child to add data to if it has no where else to go.
var _monkey_patcher: Node

# overriden in State, Persistent and Settings.
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
	await get_tree().process_frame
	_connect_to_signals()

# called by DataParser if .soda sets something that doesn't exist.
func _patch_property(key: String, patch: Variant):
	_monkey_patcher._data[key] = patch

# called by DataParser if .soda sets something that doesn't exist.
func _patch_object(key: String, type: String) -> Object:
	var obj: Object = UObject.create(type) if type else PatchableData.new()
	if obj:
		_monkey_patcher._data[key] = obj
	return obj

func _connect_to_signals():
	Mods.load_all.connect(_load_mods)
	Mods.loaded.connect(_loaded_mods)

func _load_mods(mods: Array):
	# remove old shortcuts
	_shortcuts.clear()
	# remove old states
	UNode.remove_children(self)
	
	# create monkey patcher to add spare properites to
	_monkey_patcher = preload("res://addons/sooty_engine/autoloads/patchable_state.gd").new()
	_monkey_patcher.name = "_monkey_patcher_"
	
	# init nodes from .gd scripts.
	var subdir := _get_subdir()
	for mod in mods:
		mod.meta[subdir] = []
		
		var head = mod.dir.plus_file(subdir)
		for script_path in UFile.get_files(head, ".gd"):
			var script = load(script_path)
			var state = script.new()
			if state is Node:
				mod.meta[subdir].append(script_path) # tell Mods what file has been installed
				state.set_name(UFile.get_file_name(script_path))
				add_child(state)
			else:
				# TODO: Allow resources.
				push_error("States must be node. Can't load %s." % script_path)
	
	# add monkey patcher for missing properties.
	add_child(_monkey_patcher)
	
	# collect all children in list.
	_children = get_children()
	
	# install data (.soda) to children.
	for mod in mods:
		var head = mod.dir.plus_file(subdir)
		for data_path in UFile.get_files(head, Soot.EXT_DATA):
			mod.meta[subdir].append(data_path) # tell Mods what file has been installed
			var state = DataParser.parse(data_path)
			
			# patch state objects
			DataParser.patch(self, state.data, [data_path])
			
			# collect shortcuts
			for k in state.shortcuts:
				if not k in _shortcuts:
					_shortcuts[k] = state.shortcuts[k]
				else:
					var new = state.shortcuts[k]
					var old = _shortcuts[k]
					push_error("Trying to use the same shortcut '%s' for %s and %s." % [k, old, new])

# get the default state
func _loaded_mods():
	_default = _get_state()

func _reset():
	UObject.set_state(self, _default)

func _child_added(_n: Node):
	_children = get_children()
	print("CHILDREN ", _children)

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

func _get_property_path(property: StringName) -> Array:
	var p := str(property)
	if p in _shortcuts:
		p = _shortcuts[p]
	return Array(p.split("."))
	
func _has(pname: StringName) -> bool:
	var path := _get_property_path(pname)
	var property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null and property in o:
			return true
	return false

func _get(pname: StringName):
	var path := _get_property_path(pname)
	var property = path[-1]
	for m in _children:
		var o = UObject.get_penultimate(m, path)
		if o != null:
			if property in o:
				return o[property]

func _set(pname: StringName, value) -> bool:
	var path = _get_property_path(pname)
	var property = path[-1]
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
	push_error("No %s in %s. (Attempted '%s = %s')" % [pname, _get_state(), property, value])
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
