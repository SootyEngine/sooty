@tool
extends EditorSyntaxHighlighter

func _get_name() -> String:
	return "Markdown"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var out := {}
	var txt := get_text_edit().get_line(line)
	
	out[0] = { color=Color.PALE_VIOLET_RED }
	if randf() > .5:
		out[0] = { color=Color.CYAN} 
	return out
