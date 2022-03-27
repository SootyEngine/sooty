@tool
extends FE_File

func _parse(lines: PackedStringArray):
	for i in len(lines):
		if lines[i].begins_with("#"):
			var deep := FE_Util.count(lines[i], "#")
			var name := lines[i].substr(deep).strip_edges()
			_add_chapter(i, name, deep-1)
