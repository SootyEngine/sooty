@tool
extends EditorSyntaxHighlighter

const C_NORMAL := Color.WHITE
const C_SYMBOL := Color.DARK_GRAY
const C_STRING := Color.WHITE
const C_KEY := Color.DEEP_SKY_BLUE
const C_PROPERTY := Color.DEEP_PINK
const C_INT := Color.PALE_VIOLET_RED
const C_FLOAT := Color.VIOLET
const C_COMMENT := Color.SLATE_GRAY

func _get_name() -> String:
	return "Config File"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text := get_text_edit().get_line(line)
	var out := { 0: { color=C_KEY } }
	
	var string_opened := false
	for i in len(text):
		match text[i]:
			";":
				if not string_opened:
					out[i] = { color=C_COMMENT }
					break
			
			"[", "]", "=":
				if not string_opened:
					out[i] = { color=C_SYMBOL }
					match text[i]:
						"[":
							out[i+1] = { color=C_PROPERTY }
						"=":
							var prop := text.split("=", true, 1)[-1].strip_edges()
							if prop.begins_with('"'):
								var stripped := UString.unwrap(prop, '"')
								# Colorize html colors.
								if stripped.begins_with('#') and stripped.is_valid_html_color():
									out[i+1] = { color=C_STRING.darkened(.33) }
									out[i+3] = { color=Color(stripped) }
									out[i+3+len(stripped)-1] = { color=C_STRING.darkened(.33) }
								else:
									out[i+1] = { color=C_STRING }
							else:
								out[i+1] = { color=C_INT }
			'"':
				string_opened = not string_opened
	return out
