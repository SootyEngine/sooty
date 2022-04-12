@tool
extends EditorSyntaxHighlighter

func _get_name() -> String:
	return "Soot"

const SYMBOL_ALPHA := .5

# colors
const C_TEXT := Color.GAINSBORO
const C_TEXT_INSERT := Color.PALE_GREEN
const C_SPEAKER := Color(1, 1, 1, 0.5)
const C_TAG := Color(1, 1, 1, .5)
const C_SYMBOL := Color(1, 1, 1, 0.33)
const C_SYMBOL_LIGHT := Color(1, 1, 1, 0.5)

const C_FLAG := Color.SALMON
const C_LANG := Color.YELLOW_GREEN

const C_COMMENT := Color(1.0, 1.0, 1.0, 0.25)
const C_COMMENT_LANG := Color(0.5, 1.0, 0.0, 0.5)

const C_NODE_ACTION := Color.DEEP_SKY_BLUE
const C_STATE_ACTION := Color.MEDIUM_PURPLE
const C_CONTEXT_ACTION := Color.SPRING_GREEN
const C_VAROUT := Color.ORANGE

const C_OPERATOR := Color.WHITE

const C_FLOW := Color.WHEAT
const C_FLOW_GOTO := Color.TAN
const C_FLOW_CALL := Color.TAN
const C_FLOW_END := Color.TOMATO

const C_OPTION_FLAG := Color(0.25, 0.88, 0.82, 0.5)
const C_OPTION_TEXT := Color.WHEAT

# strings
const S_FLAG := "\t#?"


const S_LIST_START := "{<"
const S_LIST_END := ">}"
const S_COND_START := "{{"
const S_COND_END := "}}"
const S_CASE_START := "{("
const S_CASE_END := ")}"

const S_PROP_START := "(("
const S_PROP_END := "))"

var index := 0
var state := {}
var text := ""

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	text = get_text_edit().get_line(line)
	state = {}
	index = 0
	var stripped = text.strip_edges()
	var out = state
	
	# meta fields
	if text.begins_with("#."):
		_c(0, C_SYMBOL)
		_c(2, Color.PALE_VIOLET_RED)
		var i := text.find(":", 2)
		if i != -1:
			_c(i, C_SYMBOL)
			_c(i+1, Color.PINK)
		return out
	
	# flag line
	elif text.begins_with(S_FLAG):
		var drk = C_FLAG.darkened(.33)
		_c(1, drk)
		_c(1+len(S_FLAG), C_FLAG)
		for i in range(1+len(S_FLAG)+1, len(text)):
			if text[i] in ",;:&|":
				_c(i, C_SYMBOL)
				_c(i+1, C_FLAG)
		return out
	
	# lang lines
	elif text.begins_with(Soot.LANG):
		_c(0, C_SYMBOL)
		_c(len(Soot.LANG), C_LANG)
	# gone lang lines 
	elif text.begins_with(Soot.LANG_GONE):
		_c(0, C_SYMBOL)
		_c(len(Soot.LANG), Color.TOMATO)
	
	# normal lines
	else:
		var from := 0
		
		# alternative line
		# TODO: Remove
#		if stripped.begins_with("?"):
#			var start := text.find("?")
#			var end := text.find(" ", start+1)
#			_c(start, C_SYMBOL)
#			_c(start+1, Color.ORANGE)
#			for i in range(start+1, end):
#				if text[i] in ",:":
#					_c(i, C_SYMBOL)
#					_c(i+1, Color.ORANGE)
#			from = end+1
		
		_c(from, C_TEXT)
		
		# flow
		if stripped.begins_with(Soot.FLOW):
			var i = text.find(Soot.FLOW)
			_c(i, C_SYMBOL)
			var clr := UClr.hue_shift(C_FLOW, .2 * i)
			clr.v -= .2 * i
			_c(i+len(Soot.FLOW), clr)
		
		else:
			if text.strip_edges().begins_with(Soot.TEXT_INSERT):
				from = text.find(Soot.TEXT_INSERT, from)
				_c(from, C_SYMBOL)
				_c(from+1, Soot.TEXT_INSERT)
				var e := text.find("=", from)
				if e != -1:
					_c(e, C_SYMBOL)
					from = e+1
			
			_h_line(from, len(text))
			
			var f = text.find('""""')
			if f != -1:
				_c(f, C_SYMBOL)
	
	# comments
	index = text.find(Soot.COMMENT)
	if index != -1:
		_c(index, C_COMMENT)
		# erase all colors afterwards
		for k in state.keys():
			if k > index:
				state.erase(k)
	
	# line id for lang
	index = text.rfind(Soot.COMMENT_LANG)
	if index != -1:
		_c(index, C_SYMBOL)
		_c(index+len(Soot.COMMENT_LANG), C_COMMENT_LANG)
	
	return state

static func split_string(s: String) -> Array:
	var out := [""]
	var in_quotes := false
	for c in s:
		if c == '"':
			if in_quotes:
				in_quotes = false
				out[-1] += '"'
			else:
				in_quotes = true
				if out[-1] == "":
					out[-1] += '"'
				else:
					out.append('"')
		
		elif c == " " and not in_quotes:
			if out[-1] != "":
				out.append("")
		
		else:
			out[-1] += c
	return out

func _c(i: int, clr: Color):
	state[i] = {color=clr}

func _h_var(from: int, v: String, index := 0, action_color := Color.WHITE):
	if not len(v):
		return
	
	# dict key
	if ":" in v:
		var p := v.split(":", true, 1)
#		_c(from, Color(action_color, .5))
		_c(from, C_SYMBOL)
		_c(from+len(p[0]), C_SYMBOL)
		_h_var(from+len(p[0])+1, p[1], 0, action_color)
	
	# array
	elif "," in v:
		var off := from
		var parts := v.split(",")
		for i in len(parts):
			var part := parts[i]
			_h_var(off, part, index, action_color)
			off += len(part)
			_c(off, C_SYMBOL)
			off += 1
	
	# match "default"
	elif v in ["_", "==", "!=", "=", "+=", "-=", ">", ">=", "<", "<="]:
		_c(from, C_SYMBOL)
	
	else:
		if v[0] == "*":
			_c(from, Color(action_color, SYMBOL_ALPHA))
			from += 1
		
		_c(from, action_color)

func _h_action_var(from: int, to: int):
	var inner := text.substr(from, to-from)
	var parts = UString.split_outside(inner, " ")
	for part in parts:
		_h_var(from, part, 0, C_VAROUT)
		from += len(part)+1

#func _h_action(from: int, to: int, is_case := false):
#	var inner := text.substr(from, to-from)
#	if inner:
#		var color = C_CONTEXT_ACTION
#		var index := 0
#		if inner.begins_with("@"):
#			_h_action_shortcut(1, from, to, C_NODE_ACTION)
#		elif inner.begins_with("~"):
#			_h_action_eval(1, from, to, C_STATE_ACTION)
#		else:
#		_h_action_eval(from, to)
#		var head = UString.get_leading_symbols(inner)
#		match head:
#			# *
#			Soot.DO_VAR: _h_action_var(from, to)
#
#			# @) @
#			Soot.DO_NODE_FUNC: _h_action_shortcut(1, from, to, C_NODE_ACTION)
#			# @:
#			Soot.DO_NODE_EVAL: _h_action_eval(2, from, to, C_NODE_ACTION)
#
#			# ~)
#			Soot.DO_SELF_FUNC: _h_action_shortcut(2, from, to, C_CONTEXT_ACTION)
#			# ~: ~
#			Soot.DO_SELF_EVAL: _h_action_eval(1, from, to, C_CONTEXT_ACTION)
#
#			# $)
#			Soot.DO_STATE_FUNC: _h_action_shortcut(2, from, to, C_STATE_ACTION)
#			# $ $:
#			Soot.DO_STATE_EVAL: _h_action_eval(1, from, to, C_STATE_ACTION)

func _h_action_shortcut(head_len: int, from: int, to: int, color: Color):
	_c(from, C_SYMBOL)
	from += head_len
	var inner := text.substr(from, to-from)
	var parts = UString.split_outside(inner, " ")
	var index := 0
	for i in len(parts):
		var part = parts[i]
		if len(part):
			if index == 0:
				_c(from, color)
				for j in len(part):
					if part[j] == ".":
						color.s -= .1
						color = UClr.hue_shift(color, -.075)
						_c(from+j, C_SYMBOL)
						_c(from+j+1, color)
				color.s = .25
				color = UClr.hue_shift(color, .5)
			else:
				_h_var(from, part, index, color)
			index += 1
		from += len(part) + 1

func _h_case(from: int, to: int):
	var parts := UString.split_outside(text.substr(from, to-from), " ")
	var clr := Color.WHITE#C_VAROUT
	var index := 0
	for i in len(parts):
		if parts[i]:
			_h_var(from, parts[i], index, clr)
			index += 1
		from += len(parts[i]) + 1
	
func _h_node_action(from: int, to: int):
	_c(from, C_SYMBOL)
	_c(from+1, C_NODE_ACTION)
	from += 1
	var parts := UString.split_outside(text.substr(from, to-from), " ")
	var clr := C_NODE_ACTION
	var index := 0
	for i in len(parts):
		if parts[i]:
			clr = C_NODE_ACTION if i == 0 else Color.GRAY if index%2==0 else Color.WHITE
			_h_var(from, parts[i], index, clr)
#			if index == 0:
#				clr = UClr.hue_shift(clr, .05)
#
#			else:
#				if index % 2==0:
#					clr = UClr.hue_shift(clr, -.01)
#				else:
#					clr = UClr.hue_shift(clr, .01)
			index += 1
				
		from += len(parts[i]) + 1
	
func _h_eval(from: int, to: int):
	_c(from, C_CONTEXT_ACTION)
	var t_color = C_CONTEXT_ACTION
	var m_color = C_CONTEXT_ACTION
	
	for i in range(from, to):
		if text[i] == "$":
			t_color = C_STATE_ACTION
			m_color = C_STATE_ACTION
			_c(i, Color(m_color, .5))
			_c(i+1, t_color)
		
		elif text[i] == "@":
			t_color = C_NODE_ACTION
			m_color = C_NODE_ACTION
			_c(i, Color(m_color, .5))
			_c(i+1, t_color)
		
		if text[i] == ".":
			t_color = UClr.hue_shift(t_color, -.033)
			_c(i, C_SYMBOL)
			_c(i+1, t_color)
		
		elif text[i] in "0123456789":
			_c(i, Color.WHITE)
		
		elif text[i] == "(":
			_c(i, C_SYMBOL)
			t_color = Color.GRAY
			_c(i+1, t_color)
		
		elif text[i] in "`'\"":
			_c(i, C_SYMBOL)
			t_color = Color.GRAY
			m_color = Color.GRAY
			_c(i+1, t_color)
		
		elif text[i] in "!-=+<>)(),[]{}":
			t_color = C_CONTEXT_ACTION
			m_color = C_CONTEXT_ACTION
			_c(i, C_SYMBOL)
			_c(i+1, t_color)

func _h_conditional(from: int, to: int):
	var inner := text.substr(from, to-from)
	var off := from
	for part in UString.split_outside(inner, " "):
		if part in ["in", "not"]:
			_c(from, C_SYMBOL)
		elif part in ["if", "elif", "else", "match", "and", "or"]:
			_c(from, C_SYMBOL)
		else:
			_h_eval(from, from+len(part))
		from += len(part) + 1

func _h_bbcode(from: int, to: int, default: Color):
	var i := from
	while i < to:
		if text[i] == "#":
			break
		elif text[i] == Soot.TEXT_LIST_START:
			var end := text.find(Soot.TEXT_LIST_END, i+1)
			if end != -1:
				# colorize open and close tags
				_c(i, C_SYMBOL)
				_h_text_list(i+1, end, default)
				_c(end, C_SYMBOL)
				# back to normal text color
				_c(end+1, default)
				i = end
			
		elif text[i] == "[":
			var end := text.find("]", i+1)
			if end != -1:
				var inner := text.substr(i+1, end-i-1)
				var off = i + 1
				for tag in inner.split(";"):
					if tag.begins_with("!"):
						tag = tag.substr(1)
						_c(off, C_SYMBOL)
						off += 1
					# colorize action tags
					if UString.begins_with_any(tag, ["~", "@"]):
						_h_eval(off, off+len(tag))
					else:
						_c(off, C_TAG)
					off += len(tag)
					# colorize ; seperator
					_c(off, C_SYMBOL)
					off += 1
				# colorize open and close tags
				_c(i, C_SYMBOL)
				_c(end, C_SYMBOL)
				# back to normal text color
				_c(end+1, default)
				i = end
		
		elif text[i] == Soot.TEXT_INSERT:
			_c(i, C_SYMBOL)
			_c(i+1, C_TEXT_INSERT)
			# TODO: look ahead a bit, and don't highlight more than needs to be
			# ie while next_line.begins_with("&")
			#		end = a
			i += 1
			while i < to and text[i] in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
				i += 1
			_c(i, default)
		
		# markdown: * ** ***
		elif text[i] == "*":
			_c(i, C_SYMBOL)
			_c(i+1, default)
	
		i += 1

func _h_flow(from := 0):
	# => and ==
	for tag in [[Soot.FLOW_GOTO, C_FLOW_GOTO], [Soot.FLOW_CALL, C_FLOW_CALL]]:
		var i := from
		while true:
			var j := text.find(tag[0], i)
			if j == -1:
				break
			var color: Color = tag[1]
			_c(j, C_SYMBOL)
			j += len(tag[0])
			_c(j, color)
			# colorize path
			for i in range(j, len(text)):
				if text[i] == ".":
					_c(i, C_SYMBOL)
					_c(i+1, color)
				elif text[i] == "/":
					color = UClr.hue_shift(color, .2)
					color.v -= .1
					_c(i, C_SYMBOL)
					_c(i+1, color)
			break

func _h_properties(from: int, to: int):
	for part in text.substr(from, to-from).split(" "):
		_h_var(from, part)
		from += len(part) + 1

func _h_line(from: int, to: int):
	var t := text.substr(from, to-from)
	var len_old = len(t)
	t = t.strip_edges(true, false)
	from += len_old - len(t)
	t = t.strip_edges(false, true)
	
	var parts := t.split(Soot.TAB_SAME_LINE)
	
	for part in parts:
		var next_from = from + len(part) + 2
		from += len(part) - len(part.strip_edges(true, false))
		to = from + len(part.strip_edges())
		part = part.strip_edges()
		_c(from, C_TEXT)
		_c(to+1, C_SYMBOL) # ;; divider
		
		# line begining with a condition.
		if part.begins_with(S_COND_START):
			# head tag {{
			_c(from, C_SYMBOL)
#			_c(from+1, C_EVAL_TAG)
			
			var end := part.find(S_COND_END)
			if end != -1:
				to = from + end
				# tail tag }}
#				_c(to, C_EVAL_TAG)
				# condition
				_h_conditional(from + len(S_COND_START), to)
				_c(to, C_SYMBOL)
				from += end + len(S_COND_END) + 1
				to = next_from-2
				part = text.substr(from, to-from)
			else:
				part = ""
		
		elif part.begins_with(S_CASE_START):
			var end := part.find(S_CASE_END)
			_c(from, C_SYMBOL)
			_c(from+1, C_SYMBOL_LIGHT)
			if end != -1:
				to = from + end
				_h_case(from + len(S_CASE_START), to)
				_c(to, C_SYMBOL_LIGHT)
				_c(to+1, C_SYMBOL)
				from += end + len(S_CASE_END) + 1
				to = next_from-2
				part = text.substr(from, to-from)
				
			else:
				part = ""
		
		# line ending with a condition.
		elif part.ends_with(S_COND_END):
			var s := part.rfind(S_COND_START, to)
			if s != -1:
				_c(from+s, C_SYMBOL)
				_h_conditional(from+s + len(S_COND_START), to - len(S_COND_END))
				_c(to-len(S_COND_END), C_SYMBOL) # }} symbol
				to = from+s
				part = text.substr(from, to-from)
		
		# language tag
		var start := part.find("#{")
		if start != -1:
			_c(from+start, C_SYMBOL)
			_c(from+start+len("#{"), Color(Color.CYAN, .5))
			
			var end := part.find("}", start)
			if end != -1:
				_c(from+end, C_SYMBOL)
				to=from+end
				part = text.substr(from, to-from)
		
		# properties
		var prop_start := part.find("((")
		if prop_start != -1:
			# head tag
			_c(from+prop_start, C_SYMBOL)
			
			var prop_end := part.find("))", prop_start)
			if prop_end != -1:
				# tail tag
				_c(from+prop_end, C_SYMBOL)
			else:
				prop_end = len(part)
			
			# inner
			_h_properties(from+prop_start+len("(("), from+prop_end)
			
			to = from+prop_start
			part = text.substr(from, to-from)
		
		
		# properties
#		if part.begins_with(S_PROPERTY):
#			var j := from + len(S_PROPERTY)
#			_c(from, C_SYMBOL)
#			_set_var_color(j, text.substr(j))
		
		# list lines
		if part.begins_with(S_LIST_START):
			# head tag
			_c(from, C_SYMBOL)
			_c(from+1, Color(Color.LIGHT_SALMON, .5))
			# inner
			_c(from+len(S_LIST_START), Color.LIGHT_SALMON)
			
			var end := part.find(S_LIST_END, len(S_LIST_START))
			if end != -1:
				# tail tag
				_c(from+end, Color(Color.LIGHT_SALMON, .5))
				_c(from+end+1, C_SYMBOL)
		
		# @node action
		elif part.begins_with("@"):
			_h_node_action(from, to)
		
		# ~ eval
		elif part.begins_with("~"):
			_c(from, C_SYMBOL)
			from += 1
			_h_eval(from, to)
		
		# options
		elif part.begins_with(Soot.CHOICE):
			_c(from, Color(C_OPTION_TEXT, .5))
			_c(from+len(Soot.CHOICE), C_OPTION_TEXT)
			_h_bbcode(from+len(Soot.CHOICE), to, C_OPTION_TEXT)
			_h_flow()
		
		# options: add
		elif part.begins_with(Soot.CHOICE_ADD):
			var c_option_add = C_OPTION_TEXT
			c_option_add.h = wrapf(c_option_add.h - .22, 0.0, 1.0)
			c_option_add.v = clampf(c_option_add.v - 0.25, 0.0, 1.0)
			_c(from, C_SYMBOL)
			_c(from+len(Soot.CHOICE_ADD), c_option_add)
			var s := text.find("*", from+len(Soot.CHOICE_ADD))
			if s != -1:
				_c(s, C_SYMBOL)
				_c(s+1, c_option_add)
		
		# flow actions == =>
		elif part.begins_with(Soot.FLOW_GOTO) or part.begins_with(Soot.FLOW_CALL):
			_h_flow()
		# flow ended ><
		elif part.begins_with(Soot.FLOW_ENDD):
			_c(from, C_FLOW_END)
			_c(from+len(Soot.FLOW_ENDD), C_FLOW_END.darkened(.33))
		# flow end all >><<
		elif part.begins_with(Soot.FLOW_END_ALL):
			_c(from, C_FLOW_END)
			_c(from+len(Soot.FLOW_END_ALL), C_FLOW_END.darkened(.33))
		# flow pass __
		elif part.begins_with(Soot.FLOW_PASS):
			_c(from, Color.YELLOW)
			_c(from+len(Soot.FLOW_PASS), Color.YELLOW.darkened(.33))
		# flow checkpoint <>
		elif part.begins_with(Soot.FLOW_CHECKPOINT):
			_c(from, Color.DEEP_SKY_BLUE)
			_c(from+len(Soot.FLOW_CHECKPOINT), Color.DEEP_SKY_BLUE.darkened(.33))
		# flow back <<
		elif part.begins_with(Soot.FLOW_BACK):
			_c(from, Color.DEEP_SKY_BLUE)
			_c(from+len(Soot.FLOW_BACK), Color.DEEP_SKY_BLUE.darkened(.33))
		
		else:
			# text
			
			var i := _find_speaker_split(part)#from)
			if i != -1:
				_c(from, C_SPEAKER)
				_c(from+i, C_SYMBOL)
				_c(from+i+1, C_TEXT)
				from = i+1
#				var sub = text.substr(from, i-from)
#				# colorize in brackets
#				if "(" in sub:
#					var a := sub.find("(")
#					var b := sub.rfind(")")
#					_c(a, C_SYMBOL)
#					_c(a+1, C_ACTION_GROUP)
#					_c(b, C_SYMBOL)
			
			_h_bbcode(from, to, C_TEXT)
		
		from = next_from

func _h_text_list(from: int, to: int, text_color: Color):
	var inner := text.substr(from, to-from)
	var parts := inner.split("|")
	for i in len(parts):
		var part := parts[i]
		if i == 0:
#			_c(from, Color.ORANGE.darkened(.33))
			_c(from, Color.ORANGE)
#			_c(from+len(part)-1, Color.ORANGE.darkened(.33))
		else:
			_c(from, text_color)
			_h_bbcode(from, from+len(part)+1, text_color)
		from += len(part)
		_c(from, C_SYMBOL)
		from += 1

func _find_speaker_split(s: String) -> int:#from: int) -> int:
	var in_bbcode := false
	for i in len(s):#range(from, len(text)):
		match s[i]:
			"[": in_bbcode = true
			"]": in_bbcode = false
			":":
				if not in_bbcode and (i==0 or s[i-1] != "\\"):
					return i
	return -1

func _find_speaker_start(from: int) -> int:
	for i in range(from, -1, -1):
		if text[i] in "}":
			return i+1
	return 0
