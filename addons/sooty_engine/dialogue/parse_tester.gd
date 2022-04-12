@tool
extends EditorScript

func get_path(current: String, next: String):
	if next.begins_with("/"):
		return next.substr(1)
	
	var path := current
	while next.begins_with("."):
		next = next.substr(1)
		if not "/" in path:
			push_error("No flow parent for ", path)
			return ""
		path = path.get_base_dir()
	
	return path.plus_file(next)
	
func _run():
	print(get_path("qall/quest/intro", ".westward"))
	
#	Mods.load_mods(false)
#	print(StringAction.eval("[$time.get_month(), $time.weekday, @enemy.name]"))
	
