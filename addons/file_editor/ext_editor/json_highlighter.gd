@tool
extends "res://addons/file_editor/ext_editor/base_highlighter.gd"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text := get_text_edit().get_line(line)
	var out := { }
	
	var is_key := true
	var in_string := false
	for i in len(text):
		match text[i]:
			"{", "}", "[", "]", ":", ",":
				if not in_string:
					out[i] = { color=C_SYMBOL }
				
				match text[i]:
					":":
						is_key = false
			
			'"':
				in_string = not in_string
				var clr := C_KEY if is_key else C_PROPERTY
				var clr_drk := clr.darkened(.25)
				if in_string:
					out[i] = { color=clr_drk }
					out[i+1] = { color=clr }
				else:
					out[i] = { color=clr_drk }
					out[i+1] = { color=C_NORMAL }
	
	return out
