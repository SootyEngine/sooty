extends ConfigFile
class_name Config

func _init(path: String = ""):
	if path != "":
		if self.load(path) == OK:
			pass

func get_color(section: String, key: String, default := Color.WHITE) -> Color:
	var v = get_value(section, key, default)
	if v is String:
		if v.is_valid_html_color():
			return Color(v)
		if Color().find_named_color(v) != -1:
			return Color(v)
	elif v is Color:
		return v
	return default
