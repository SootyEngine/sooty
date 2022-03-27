@tool
extends CodeHighlighter

# operators
const OP_RELATIONS := ["==", "!=", "<", "<=", ">", ">="]
const OP_ASSIGNMENTS := ["=", "+=", "-="]

# colors
const C_TEXT := Color.WHITE
const C_SYMBOL := Color.DARK_GRAY
const C_VAR_BOOL := Color.ORANGE_RED
const C_VAR_FLOAT := Color.ORANGE
const C_VAR_INT := Color.ORANGE
const C_VAR_UNKOWN := Color.PALE_GOLDENROD
const C_SPEAKER := Color.AQUAMARINE
const C_COMMENT := Color(.5, .5, .5, 1.0)
const C_FE_TAG := Color.PALE_VIOLET_RED
const C_ACTION := Color.PLUM
const C_FLOW := Color.DEEP_SKY_BLUE
const C_FLOW_GOTO := Color.DEEP_SKY_BLUE
const C_FLOW_CALL := Color.PLUM
const C_PROPERTY_TAG := Color.GRAY
const C_PROPERTY := Color.SLATE_GRAY
const C_CONDITION := Color.WHEAT
const C_CONDITION_TAG := Color.PALE_VIOLET_RED
const C_OPTION_TAG := Color.DEEP_SKY_BLUE
const C_OPTION_TAG_INNER := Color.LIGHT_SKY_BLUE
const C_OPTION_TEXT := Color.LIGHT_BLUE

# strings
const S_FLOW := "==="
const S_FLOW_GOTO := ">>"
const S_FLOW_CALL := "::"
const S_COMMENT := "//"
const S_ACTION := "@"
const S_PROPERTY_TAG_START := "(("
const S_PROPERTY_TAG_END := "))"
const S_CONDITION_TAG_START := "{{"
const S_CONDITION_TAG_END := "}}"

func c(clr: Color):
	return {color=clr}

func _get_var_color(v: String) -> Color:
	if v.begins_with("$"): return Color.HOT_PINK
	if v.is_valid_int(): return C_VAR_INT
	if v.is_valid_float(): return C_VAR_FLOAT
	if v in ["true", "false"]: return C_VAR_BOOL
	return C_VAR_UNKOWN

# colorize comments
func _h_comment(raw: String, out: Dictionary):
	var i = raw.find(S_COMMENT)
	if i != -1:
		out[i] = { color=C_COMMENT }
		
		# erase all colors afterwards
		for k in out.keys():
			if k > i:
				out.erase(k)
		
		# tags
#		var open := false
#		for j in range(i+len(S_COMMENT), len(raw)):
#			if raw[j] == "#":
#				open = true
#				out[j+1] = { color=C_FE_TAG }
#			elif raw[j] == " " and open:
#				open = false
#				out[j] = { color=C_COMMENT }

func _h_action(raw: String, from: int, to: int, out: Dictionary):
	var c := raw.find(S_ACTION, from)
	var inner := raw.substr(from, to-from).strip_edges()
	var p := inner.split(" ")
	
	for i in len(p):
		var w := p[i]
		if i == 0:
			var clr := C_ACTION
			if len(p) == 3 and p[1] in OP_ASSIGNMENTS:
				clr=_get_var_color(w)
			out[c] = { color=clr.darkened(.33) }
			out[c+1] = { color=clr }
			if "." in p[0]:
				out[c+p[0].find(".")] = { color=clr.darkened(.33) }
		# operation assignment
		elif i == 1 and w in OP_ASSIGNMENTS:
			out[c] = { color=C_SYMBOL }
		# dictionary
		elif ":" in w:
			var f := w.find(":")
			var v = w.substr(f+1)
			out[c] = { color=C_PROPERTY }
			out[c+f] = { color=C_SYMBOL }
			out[c+f+1] = { color=_get_var_color(v) }
		# array
		elif "," in w:
			var oldc = c
			for p in w.split(","):
				out[c] = { color=_get_var_color(p) }
				out[c+len(p)] = { color=C_SYMBOL }
				c += len(p) + 1
			c = oldc
		# bit
		elif "|" in w:
			var oldc = c
			for p in w.split("|"):
				out[c] = { color=_get_var_color(p) }
				out[c+len(p)] = { color=C_SYMBOL }
				c += len(p) + 1
			c = oldc
		else:
			out[c] = { color=_get_var_color(w) }
		c += len(w) + 1
	
	out[to] = C_TEXT

func _h_conditional(raw: String, from: int, to: int, out: Dictionary):
	var parts = raw.substr(from, to-from).split(" ")
	var off := from
	for part in parts:
		if part in ["==", "!=", ">", ">=", "<", "<="]:
			out[off] = { color=C_SYMBOL }
		else:
			out[off] = { color=_get_var_color(part) }
		off += len(part) + 1

func _h_properties(raw: String, out: Dictionary, default: Color):
	var i := raw.rfind("((")
	if i != -1:
		out[i] = {color=C_PROPERTY_TAG}
		out[i+len("((")] = {color=default}
		
		var j := raw.find("))", i+len("(("))
		if j != -1:
			out[j] = {color=C_PROPERTY_TAG}
			out[i+len("))")] = {color=default}

			var inner := raw.substr(i+len("(("), j-i-len("(("))
			var parts := inner.split(" ")
			var off := i+len("((")
			_h_property_keys(raw, off, parts, out)
			
func _h_property_keys(raw: String, off: int, parts: PackedStringArray, out: Dictionary):
	for k in len(parts):
		if ":" in parts[k]:
			var p := parts[k].split(":")
			out[off] = {color=C_PROPERTY}
			off += len(p[0])
			out[off] = {color=C_SYMBOL}
			out[off+1] = {color=_get_var_color(p[1])}
			off += len(p[1])+1
			off += 1

func _h_bbcode(raw: String, from: int, out: Dictionary, default: Color):
	var i := from
	while i < len(raw):
#	for i in range(from, len(raw)):
		match raw[i]:
			"[", ";", "=":
				out[i] = { color=default.darkened(.5) }
				out[i+1] = { color=default.darkened(.25) }
				i += 1
			"$":
				out[i] = { color=Color.HOT_PINK }
				i += 1
			"@":
				var end = raw.find(";", i)
				if end == -1:
					end = raw.find("]", i)
					if end == -1:
						end = len(raw)
				_h_action(raw, i, end, out)
				i = end+1
				
			"*":
				out[i] = { color=default.darkened(.5) }
				out[i+1] = { color=default }
				i += 1
				
			"]":
				out[i] = {color=default.darkened(.5) }
				out[i+1] = {color=default}
				i += 1
				
			_:
				i += 1

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text := get_text_edit().get_line(line)
	var stripped = text.strip_edges()
	var out = {}
	
	if text.begins_with(S_FLOW):
		out[0] = { color=C_FLOW.darkened(.25) }
		out[len(S_FLOW)] = { color=C_FLOW }
	
	elif stripped.begins_with("|"):
		var i := text.find("|")
		out[i] = { color=C_SYMBOL }
		out[i+1] = { color=C_TEXT }
		var parts := text.substr(i+1).split(" ")
		_h_property_keys(text, i+1, parts, out)
		
	# conditionals
	elif stripped.begins_with("{{"):
		out[0] = { color=C_SYMBOL }
		var start := len(text) - len(text.strip_edges(true, false))
		start = text.find("{{", start)
		var end := text.rfind("}}")
		out[end] = { color=C_SYMBOL }
		_h_conditional(text, start+len("{{"), end, out)
	
	# action
	elif stripped.begins_with(S_ACTION):
		_h_action(text, 0, len(text), out)
	
	# options
	elif stripped.begins_with(">"):
		var a := text.find(">")
		var b := text.find(">", a)
		out[a] = { color=C_OPTION_TAG }
		out[a+len(">")] = { color=C_OPTION_TAG }
#		out[a+1] = { color=C_OPTION_TAG_INNER }
#		out[b] = { color=C_OPTION_TAG }
#		out[b+1] = { color=C_OPTION_TEXT }
		
		_h_bbcode(text, a+len(">"), out, C_OPTION_TEXT)
#		_h_bbcode(text, b+1, out, C_OPTION_TEXT)
		
		if S_CONDITION_TAG_START in text:
			var i = text.find(S_CONDITION_TAG_START, a)
			out[i] = { color=C_CONDITION_TAG }
			
			if S_CONDITION_TAG_END in text:
				var j = text.find(S_CONDITION_TAG_END, i)
				out[j] = { color=C_CONDITION_TAG }
				_h_conditional(text, i+2, j-1, out)
		
		if S_FLOW_GOTO in text:
			var i = text.rfind(S_FLOW_GOTO)
			out[i] = { color=C_FLOW.darkened(.33) }
			out[i+2] = { color=C_FLOW }
	
	elif stripped.begins_with(S_FLOW_GOTO):
		var i = text.rfind(S_FLOW_GOTO)
		out[0] = { color=C_FLOW_GOTO.darkened(.33) }
		out[i+2] = { color=C_FLOW_GOTO }
	
	elif stripped.begins_with(S_FLOW_CALL):
		var i = text.rfind(S_FLOW_CALL)
		out[0] = { color=C_FLOW_CALL.darkened(.33) }
		out[i+2] = { color=C_FLOW_CALL }
	
	else:
		# text
		if ":" in text:
			var i := text.find(":")
			out[0] = { color=C_SPEAKER }
			out[i] = { color=C_SYMBOL }
			out[i+1] = { color=C_TEXT }
		
		else:
			out[0] = { color=C_TEXT }
		
		_h_bbcode(text, 0, out, C_TEXT)
	
	_h_properties(text, out, C_TEXT)
	_h_comment(text, out)
	return out
