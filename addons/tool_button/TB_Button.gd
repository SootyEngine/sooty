extends HBoxContainer

var button := Button.new()
var info: Dictionary
var object: Object
var pluginref: EditorPlugin

func _init(obj: Object, d, p):
	object = obj
	pluginref = p
	
	alignment = BoxContainer.ALIGNMENT_CENTER
	size_flags_horizontal = SIZE_EXPAND_FILL
	
	if d is String:
		info = {call=d}
	
	elif d is Callable:
		info = {
			call=d,
			text=str(d.get_method()).capitalize()
		}
	elif d is Array:
		info = {
			call = d,
			text = "+".join(d.map(_get_label))
		}
	else:
		info = d
	
	add_child(button)
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.text = _get_label(info)
	button.modulate = _get_key_or_call("tint", TYPE_COLOR, Color.WHITE)
	button.disabled = _get_key_or_call("lock", TYPE_BOOL, false)
	
	button.button_down.connect(self._on_button_pressed)
	
	if "hint" in info:
		button.hint_tooltip = _get_key_or_call("hint", TYPE_STRING, "")
	else:
		button.hint_tooltip = "%s(%s)" % [info.call, _get_args_string()]
	
	button.flat = info.get("flat", false)
	button.alignment = info.get("align", BoxContainer.ALIGNMENT_CENTER)
	
	if "icon" in info:
		button.expand_icon = false
		button.set_button_icon(load(_get_key_or_call("icon", TYPE_STRING, "")))

func _get_label(x: Variant) -> String:
	if x is String:
		return x.capitalize()
	elif x is Callable:
		return str(x.get_method()).capitalize()
	elif x is Dictionary:
		if "text" in x:
			return x.text
		else:
			return _get_label(x.call)
	else:
		return "???"

func _get_key_or_call(k: String, t: int, default):
	if k in info:
		if typeof(info[k]) == t:
			return info[k]
		elif info[k] is Callable:
			return info[k].call()
		else:
			print("TB_BUTTON: Shouldn't happen.")
	else:
		return default

func _get_args_string():
	if not "args" in info:
		return ""
	var args = ""
	for a in info.args:
		if not args == "":
			args += ", "
		if a is String:
			args += '"%s"' % [a]
		else:
			args += str(a)
	return args

func _call(x: Variant):
	if x is Dictionary:
		_call(x.call)
	
	elif x is String:
		# special internal editor actions.
		if x.begins_with("@"):
			var p = x.substr(1).split(";")
			match p[0]:
				"SCAN":
					pluginref.get_editor_interface().get_resource_filesystem().scan()
				
				"CREATE_AND_EDIT":
					var f := File.new()
					f.open(p[1], File.WRITE)
					f.store_string(p[2])
					f.close()
					var rf: EditorFileSystem = pluginref.get_editor_interface().get_resource_filesystem()
					rf.update_file(p[1])
					rf.scan()
					rf.scan_sources()
					
					pluginref.get_editor_interface().select_file(p[1])
					pluginref.get_editor_interface().edit_resource.call_deferred(load(p[1]))
					
				"SELECT_AND_EDIT":
					if File.new().file_exists(p[1]):
						pluginref.get_editor_interface().select_file(p[1])
						pluginref.get_editor_interface().edit_resource.call_deferred(load(p[1]))
					else:
						push_error("Nothing to select and edit at %s." % p[1])
				"SELECT_FILE":
					if File.new().file_exists(p[1]):
						pluginref.get_editor_interface().select_file(p[1])
					else:
						push_error("No file to select at %s." % p[1])
				"EDIT_RESOURCE":
					if File.new().file_exists(p[1]):
						pluginref.get_editor_interface().edit_resource.call_deferred(load(p[1]))
					else:
						push_error("No resource to edit at %s." % p[1])
			return null
		else:
			return object.call(x)
	
	elif x is Callable:
		return x.call()
	
	elif x is Array:
		for item in x:
			_call(item)
	
	else:
		push_error("Hmm?")

func _edit(file: String):
	pluginref.get_editor_interface().select_file(file)
	pluginref.get_editor_interface().edit_resource.call_deferred(ResourceLoader.load(file, "TextFile", 0))

func _on_button_pressed():
	var returned
	
#	if info.call is String:
#		if "args" in info:
#			returned = object.callv(info.call, info.args)
#		else:
#			returned = object.call(info.call)
#
#	elif info.call is Callable:
#		returned = info.call.call()
#
#	elif info.call is Array:
#		for item in info.call:
#			returned = object.call(item)
#	returned =
	_call(info)
	
#	if info.get("print", true) and returned != null:
#		var a = _get_args_string()
#		if a:
#			print(">> %s(%s): %s" % [info.call, a, returned])
#		else:
#			print(">> %s: %s" % [info.call, returned])
#
#	if info.get("update_filesystem", false):
#		pluginref.rescan_filesystem()
