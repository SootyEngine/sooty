extends FE_File

func get_errors(text: String) -> Array:
	var json := JSON.new()
	if json.parse(text) != OK:
		return [[json.get_error_line(), json.get_error_message()]]
	return super.get_errors(text)

func _parse(lines: PackedStringArray):
	for i in len(lines):
		if ": {" in lines[i]:
			var unstripped := lines[i].split(": {", true, 1)[0]
			var title := unstripped.strip_edges()
			var deep := len(unstripped) - len(title) - 1
			title = title.substr(1, len(title)-2)
			_add_chapter(i, title, deep)
