@tool
extends Resource
class_name FE_Util

static func load_text(path: String) -> String:
	var f := File.new()
	f.open(path, File.READ)
	var out := f.get_as_text()
	f.close()
	return out

static func save_text(path: String, text: String) -> bool:
	var f := File.new()
	f.open(path, File.WRITE)
	f.store_string(text)
	f.close()
	return true

static func load_cfg(path: String) -> ConfigFile:
	var c := ConfigFile.new()
	c.load(path)
	return c

static func is_shortcut(e: InputEvent, s: Shortcut) -> bool:
	if e is InputEventKey:
		for k in ["keycode", "pressed", "echo", "ctrl_pressed", "alt_pressed", "shift_pressed"]:
			if not e[k] == s.events[0][k]:
				return false
		return true
	return false

# only works with a-z
static func str_to_shortcut(s: String) -> Shortcut:
	var keys := s.split("+")
	var event := InputEventKey.new()
	event.pressed = true
	
	# first few commands are control keys
	for i in len(keys)-1:
		match keys[i]:
			"alt": event.alt_pressed = true
			"meta": event.meta_pressed = true
			"ctrl": event.ctrl_pressed = true
			"shift": event.shift_pressed = true
	
	# followed by 
	var last := keys[-1]
	for keycode in range(KEY_A, KEY_Z+1) + range(KEY_0, KEY_9+1) + range(KEY_F1, KEY_F12+1) + [KEY_PLUS, KEY_MINUS]:
		if last == OS.get_keycode_string(keycode).to_lower():
			event.keycode = keycode
			break
	
	var out := Shortcut.new()
	out.events = [event]
	return out

static func print_json(json:Dictionary):
	print(JSON.new().stringify(json, "\t", false))

static func count(t: String, c: String) -> int:
	var i := 0
	while t.begins_with(c):
		t = t.trim_prefix(c)
		i += 1
	return i

static func get_nested(object: Object, property: String, default: Variant = null):
	var parts := property.split(".")
	var out = object
	
	for part in parts:
		if not part in out:
			push_error("No '%s' in %s at '%s'." % [property, object, part])
			return default
		out = out[part]
	
	return out

static func set_nested(object: Object, property: String, value: Variant) -> bool:
	var parts := property.split(".")
	var obj = object
	
	for i in len(parts)-1:
		if not parts[i] in obj:
			push_error("No '%s' in %s at '%s'." % [property, object, parts[i]])
			return false
		obj = obj[parts[i]]
	
	if not parts[-1] in obj:
		push_error("No '%s' in %s at '%s'." % [property, object, parts[-1]])
		return false
	
	obj[parts[-1]] = value
	return true
