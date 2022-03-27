extends HBoxContainer

var button:Button = Button.new()
var object:Object
var info:Dictionary
var pluginref

func _init(obj:Object, d, p):
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
	button.modulate = _get_key_or_lambda("tint", TYPE_COLOR, Color.WHITE)
	button.disabled = _get_key_or_lambda("lock", TYPE_BOOL, false)
	
	button.button_down.connect(self._on_button_pressed)
	button.hint_tooltip = "%s(%s)" % [info.call, _get_args_string()]
	
	if "hint" in info:
		button.hint_tooltip += "\n%s" % _get_key_or_lambda("hint", TYPE_STRING, "")
	
	button.flat = info.get("flat", false)
	button.alignment = info.get("align", BoxContainer.ALIGNMENT_CENTER)
	
	if "icon" in info:
		button.expand_icon = false
		button.set_button_icon(load(_get_key_or_lambda("icon", TYPE_STRING, "")))

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

func _get_key_or_lambda(k:String, t:int, default):
	if k in info:
		if typeof(info[k]) == t:
			return info[k]
		# lambda
		else:
			return info[k].call()
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
		
#func _get_label():
#	if "text" in info:
#		return _get_key_or_lambda("text", TYPE_STRING, "")
#
#	if info.call is String:
#		return info.call.capitalize()
#
#	# lambda
#	return "(unnamed lambda)"

func _call(x: Variant):
	if x is Dictionary:
		return _call(x.call)
	elif x is String:
		return object.call(x)
	elif x is Callable:
		return x.call()
	elif x is Array:
		var out := []
		for item in x:
			out.append(_call(item))
		return out
	else:
		push_error("Hmm?")

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
	returned = _call(info)
	
	if info.get("print", true) and returned != null:
		var a = _get_args_string()
		if a:
			print(">> %s(%s): %s" % [info.call, a, returned])
		else:
			print(">> %s: %s" % [info.call, returned])
	
	if info.get("update_filesystem", false):
		pluginref.rescan_filesystem()
