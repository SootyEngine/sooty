@tool
extends RefCounted

signal _changed(property: String)
signal changed(property: Array)
signal changed_to(property: Array, to: Variant)
signal changed_from_to(property: Array, from: Variant, to: Variant)

# won't emit signals when changing things.
@export var _silent := false
# state has changed.
@export var _has_changed := false
# shorter keys to nested data. (ie: p = characters:player)
@export var _shortcuts := {}
# the default state, after all mods were installed.
@export var _default := {}
# all the child nodes
@export var _states := []
@export var _state_properties := []
# a child to add data to if it has no where else to go.
var _monkey_patcher: RefCounted

# 
@export var _calls := {}
@export var _call_names := {}

func _ready() -> void:
	Sooty.mods.load_all.connect(_load_mods)
	Sooty.mods._loaded.connect(_loaded_mods)

func get_method_names() -> Array:
	return _calls.keys()

func get_first(type: Variant) -> Variant:
	# find the first object of a class_name
	if type is String:
		for state in _states:
			var props := UObject.get_state_properties(state)
			for property in props:
				if state[property] is Object and state[property].get_class() == type:
					return state[property]
	# find the first object, using an actual class reference
	else:
		for state in _states:
			var props := UObject.get_state_properties(state)
			for property in props:
				if state[property] is type:
					return state[property]
	return null

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

# called by DataParser if .soda sets something that doesn't exist.
func _patch_property(key: String, patch: Variant):
	_monkey_patcher._data[key] = patch

# called by DataParser if .soda sets something that doesn't exist.
func _patch_property_object(key: String, type: String) -> Object:
	var obj: Object = UClass.create(type) if type else PatchableData.new()
#	print("%s:%s++ %s:%s" % [_get_subdir(), type, key, UClass.get_class_name(obj)])
	if obj:
		_monkey_patcher._data[key] = obj
	return obj

func _load_mods(mods: Array):
	# remove old state data
	_shortcuts.clear()
	_state_properties.clear()
	_calls.clear()
	_call_names.clear()
	
	# remove old states
	UGroup.remove(_get_node_group())
	
	# create monkey patcher to add spare properites to
	_monkey_patcher = preload("res://addons/sooty_engine/autoloads/_monkey_patcher_.gd").new()
	_states = [_monkey_patcher]
	
	# init nodes from .gd scripts.
	var all_files := []
	var subdir := _get_subdir()
	for mod in mods:
		mod.meta[subdir] = []
		
		var head = mod.dir.plus_file(subdir)
		var script_paths := UFile.get_files(head, ".gd")
		
		all_files.append_array(script_paths)
		
		for script_path in script_paths:
			mod.meta[subdir].append(script_path) # tell Mods what file has been installed
			
			# collect state
			var script = load(script_path)
			var state = script.new()
			_states.append(state)
			
			# collect potential shortcuts
			if "_shortcuts" in state:
				UDict.merge(_shortcuts, state._shortcuts)
			
			# add to tree if it's a node
			if state is Node:
				state.set_name(UFile.get_file_name(script_path))
				Sooty.add_child(state)
				state.add_to_group(_get_node_group())
			
			elif state is Resource or state is RefCounted:
				pass
			
			else:
				# TODO: Allow resources.
				push_error("States must be Node or Resource/RefCounted. Can't load %s." % script_path)
	
	# collect methods in a way where they can all be called from the state
	for state in _states:
		_state_properties.append_array(UObject.get_state_properties(state))
		for method in UReflect.get_script_methods(state):
			_call_names[method] = "_calls.%s.call(" % method
			_calls[method] = Callable(state, method)
	
	# patch data (.soda) to state.
	for mod in mods:
		var head = mod.dir.plus_file(subdir)
		var data_files := UFile.get_files(head, "." + Soot.EXT_DATA)
		
		all_files.append_array(data_files)
		
		for data_path in data_files:
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
					push_error("Same shortcut '%s' for %s and %s." % [k, old, new])
	
	# create a file scanner to keep track of modified files
	var file_scanner := FileModifiedScanner.new()
	Global.add_child(file_scanner)
	file_scanner.set_name("FileScanner")
	file_scanner.add_to_group(_get_node_group())
	file_scanner.modified.connect(_files_modified.bind(file_scanner))
	file_scanner.set_files(all_files)

func _get_node_group() -> String:
	return "_s_%s_" % [_get_subdir()]

func _files_modified(file_scanner: FileModifiedScanner):
	file_scanner.update_times()
	Sooty.mods.load_mods()

# get the default state
func _loaded_mods():
	_default = _get_state()
	
	# output to debug file
	if UFile.exists("res://debug_output/states"):
		var path = "res://debug_output/states/_%s.soda" % [_get_subdir()]
		var text := DataParser.new().dict_to_str(_default, true, false, true)
		UFile.save_text(path, text)

func _reset():
	UObject.set_state(self, _default)

func _has_method(method: String) -> bool:
	return method in _calls

func _get_method_parent(method: String) -> Node:
	return _calls[method].get_object()

func _get_methods() -> Dictionary:
	var out := {}
	for state in _states:
		UDict.merge(out, UReflect.get_methods(state))
	return out
	
func _get_script_methods() -> Dictionary:
	var out := {}
	for state in _states:
		for method in UReflect.get_script_methods(state):
			out[method] = UReflect.get_method_info(state, method)
	return out

# preprocess an eval, so it can call all methods of children
func _preprocess_eval(eval: String) -> String:
	return eval.format(_call_names, "_(")

func _call(method: String, args: Array = [], as_string_args := false, default = null) -> Variant:
	if "." in method:
		var p := method.rsplit(".", true, 1)
		method = p[1]
		if _has(p[0]):
			var target = _get(p[0])
			return UObject.call_w_kwargs([target, method], args, as_string_args)
		else:
			push_error("No function '%s' in %s at '%s'." % [p[0], _get_subdir(), method])
			return default
	
	if method in _calls:
		var got = UObject.call_w_kwargs(_calls[method], args, as_string_args)
		prints("CALL (%s) w (%s) and got (%s)" % [method, args, got])
		return got
	# call the first method we find
#	for state in _children:
#		if 
#		if state.has_method(method):
#			return UObject.call_w_kwargs([state, method], args, as_string_args)
	UString.push_error_similar("No method '%s' in %s." % [method, _get_subdir()], method, get_method_names())
	return default

func _reset_state():
	UObject.set_state(self, _default)

func _get_changed_states() -> Dictionary:
	var current := _get_state()
	return UDict.get_different(_default, current)

func _get_state() -> Dictionary:
	var out := {}
	for state in _states:
		UDict.merge(out, UObject.get_state(state), true)
	return out

func _get_state_properties() -> Array:
	var out := []
	for state in _states:
		out.append_array(UObject.get_state_properties(state))
	return out

func _get_property_path(property: StringName) -> Array:
	var p := str(property)
	if p in _shortcuts:
		p = _shortcuts[p]
	return Array(p.split("."))
	
func _has(pname: StringName) -> bool:
	var path := _get_property_path(pname)
	var property = path[-1]
	for state in _states:
		var o = UObject.get_penultimate(state, path)
		if o != null and property in o:
			return true
	return false

func _get(pname: StringName):
	var path := _get_property_path(pname)
	for state in _states:
		var o = UObject.get_penultimate(state, path)
		var property = path[-1]
		if o != null:
			if property in o:
				return o[property]

func _set(pname: StringName, value) -> bool:
	var path = _get_property_path(pname)
	var property = path[-1]
	for state in _states:
		var o = UObject.get_penultimate(state, path)
		if o != null and property in o:
			var old = o.get(property)
			if typeof(value) != typeof(old):
				push_error("Can't set %s (%s) to %s (%s)." % [property, UType.get_name_from_type(typeof(old)), value, UType.get_name_from_type(typeof(value))])
				return true
			o.set(property, value)
			var new = o.get(property)
			if old != new:
				if not _silent:
					_has_changed = true
					_changed.emit(pname)
					changed.emit(path)
					changed_to.emit(path, new)
					changed_from_to.emit(path, old, new)
			return true
	push_error("No %s in %s. (Attempted '%s = %s')" % [pname, _get_state(), property, value])
	return true
