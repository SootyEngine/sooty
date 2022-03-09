extends FE_File

func _parse(lines: PackedStringArray):
	for i in len(lines):
		if lines[i].begins_with("["):
			var title := lines[i].substr(len("[")).split("]")[0].strip_edges()
			_add_chapter(i, title, 0)
