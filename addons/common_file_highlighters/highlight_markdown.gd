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
	return "Markdown"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text := get_text_edit().get_line(line)
	var stripped := text.strip_edges()
	
	var out := { 0: { color=C_NORMAL } }
	var clr := C_NORMAL
	
	if stripped == "":
		return out
	
	if stripped in ["---", "***", "___", "- - -", "* * *", "_ _ _"]:
		out[0] = { color=C_SYMBOL }
		return out
	
	if text.begins_with("#"):
		var i := text.rfind("#")
		out[0] = { color=C_KEY.darkened(.33) }
		out[i+1] = { color=C_KEY }
		return out
	
	if stripped[0] in "-+*":
		var i := len(text) - len(stripped)
		out[i] = { color=C_SYMBOL }
		out[i+1] = { color=C_NORMAL }
	
	elif stripped[0].is_valid_int():
		var i := len(text) - len(stripped)
		var d := text.find(".", i)
#		var s := text.find(" ", i)
		if d != -1:
			out[i] = { color=C_SYMBOL }
			out[d+1] = { color=C_NORMAL }
	
	if "<!--" in text:
		var i := text.find("<!--")
		out[i] = { color=C_COMMENT.darkened(.25) }
		out[i+len("<!--")] = { color=C_COMMENT }
		
		var j := text.find("-->", i+len("<!--"))
		if j != -1:
			out[j] = { color=C_COMMENT.darkened(.25) }
			out[j+len("-->")] = { color=clr }
		return out
	
	if stripped.begins_with(">"):
		var i := len(text) - len(stripped)
		out[i] = { color=C_INT.darkened(.33) }
		out[i+1] = { color=C_INT }
		clr = C_INT
	
	var in_link := false
	var in_link_desk := false
	var in_table := false
	var in_html := false
	for i in len(text):
		match text[i]:
			"[":
				in_link = true
				out[i] = { color=C_SYMBOL }
				out[i+1] = { color=C_KEY }
			"]":
				in_link = false
				out[i] = { color=C_SYMBOL }
				out[i+1] = { color=C_NORMAL }
			"(":
				if i != 0 and text[i-1] == "]":
					in_link_desk = true
					out[i] = { color=C_SYMBOL }
					out[i+1] = { color=C_PROPERTY }
			")":
				if in_link_desk:
					in_link_desk = false
					out[i] = { color=C_SYMBOL }
					out[i+1] = { color=C_NORMAL }
			
			"<":
				in_html = true
				out[i] = { color=Color.ORANGE.darkened(.33) }
				out[i+1] = { color=Color.ORANGE }
			
			">":
				in_html = false
				out[i] = { color=Color.ORANGE.darkened(.33) }
				out[i+1] = { color=clr }
			
			# tables
			"|":
				in_table = true
				out[i] = { color=C_SYMBOL }
				out[i+1] = { color=C_NORMAL }
			
			":", "-":
				if in_table:
					out[i] = { color=C_SYMBOL }
					out[i+1] = { color=C_NORMAL }
	
	var i := 0
	for t in ["***", "___", "~~", "**", "__", "*", "_" , "`"]:
		while i < len(text):
			var a := text.find(t, i)
			if a == -1:
				break
			var b := text.find(t, a+len(t))
			if b == -1:
				break
			var c = clr
			c.h += len(t) * .1
			c.s += len(t) * .1
			out[a] = { color=c.darkened(.33) }
			out[a+len(t)] = { color=c }
			out[b] = { color=c.darkened(.33) }
			out[b+len(t)] = { color=clr }
			i = b + len(t)
	
	return out
