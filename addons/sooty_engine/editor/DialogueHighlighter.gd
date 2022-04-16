@tool
extends EditorSyntaxHighlighter

func _get_name() -> String:
	return "Soot"

const SYMBOL_ALPHA := .5

# colors
const C_TEXT := Color.GAINSBORO
const C_TEXT_INSERT := Color.PALE_GREEN
const C_TEXT_PREDICATE := Color.PALE_TURQUOISE# Color(0.5, 0.7, 1.0, 1.0)
const C_SPEAKER := Color(1, 1, 1, 0.5)
const C_TAG := Color(1, 1, 1, .4)
const C_SYMBOL := Color(1, 1, 1, 0.3)
const C_SYMBOL_LIGHT := Color(1, 1, 1, 0.5)

const C_FLAG := Color.SALMON
const C_LANG := Color.YELLOW_GREEN

const C_COMMENT := Color(1.0, 1.0, 1.0, 0.25)
const C_COMMENT_LANG := Color(0.5, 1.0, 0.0, 0.5)

const C_NODE_ACTION := Color.DEEP_SKY_BLUE
const C_STATE_ACTION := Color.MEDIUM_PURPLE
const C_PERSISTENT_ACTION := Color.GOLD
const C_CONTEXT_ACTION := Color.SPRING_GREEN
const C_VAROUT := Color.ORANGE

const C_OPERATOR := Color.WHITE

const C_FLOW := Color.WHEAT
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
var deep := 0
var state := {}
var text := ""
var current_line := 0

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	text = get_text_edit().get_line(line)
	current_line = line
	state = {}
	index = 0
	deep = UString.count_leading(text, "\t")
	var stripped = text.strip_edges()
	var out = state
	
	# meta fields
	var start := text.find("#.")
	if start != -1:
		_c(start, C_SYMBOL)
		_c(start+2, Color.PALE_VIOLET_RED)
		var i := text.find(":", start+2)
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
			_c(i+len(Soot.FLOW), get_flow_color(deep))
		
		else:
			if text.strip_edges().begins_with(Soot.TEXT_INSERT):
				from = text.find(Soot.TEXT_INSERT, from)
				_c(from, C_SYMBOL)
				_c(from+1, C_TEXT_INSERT)
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
#	index = text.rfind(Soot.COMMENT_LANG)
#	if index != -1:
#		_c(index, C_SYMBOL)
#		_c(index+len(Soot.COMMENT_LANG), C_COMMENT_LANG)
	
	return state

# go backwards through the lines and try to find the flow/path/to/this/node.
func _find_true_depth() -> int:
	var line := current_line
	var t := get_text_edit()
	while line >= 0:
		var text := t.get_line(line)
		var i := text.find("===")
		if i != -1:
			return i
		line -= 1
	return deep

#static func split_string(s: String) -> Array:
#	var out := [""]
#	var in_quotes := false
#	for c in s:
#		if c == '"':
#			if in_quotes:
#				in_quotes = false
#				out[-1] += '"'
#			else:
#				in_quotes = true
#				if out[-1] == "":
#					out[-1] += '"'
#				else:
#					out.append('"')
#
#		elif c == " " and not in_quotes:
#			if out[-1] != "":
#				out.append("")
#
#		else:
#			out[-1] += c
#	return out

func _c(i: int, clr: Color):
	state[i] = {color=clr}

func _h_var(from: int, v: String, index: int):
	if not len(v):
		return
	
	# dict key
	if ":" in v:
		var p := v.split(":", true, 1)
		_c(from, C_SYMBOL)
		_c(from+len(p[0]), C_SYMBOL)
		_h_var(from+len(p[0])+1, p[1], 0)
	
	# array
	elif "," in v:
		var off := from
		var parts := v.split(",")
		for i in len(parts):
			var part := parts[i]
			_h_var(off, part, index)
			off += len(part)
			_c(off, C_SYMBOL)
			off += 1
	
	# match "default"
	elif v in ["_", "==", "!=", "=", "+=", "-=", ">", ">=", "<", "<="]:
		_c(from, C_SYMBOL)
	
	else:
		if v[0] == "*":
			_c(from, Color(Color.WHITE, SYMBOL_ALPHA))
			from += 1
		
		_c(from, Color.DARK_GRAY if index % 2 != 0 else Color.WEB_GRAY)

func _h_action_var(from: int, to: int):
	var inner := text.substr(from, to-from)
	var parts = UString.split_outside(inner, " ")
	for part in parts:
		_h_var(from, part, 0)
		from += len(part)+1

func _h_case(from: int, to: int):
	var parts := UString.split_outside(text.substr(from, to-from), " ")
	var clr := Color.WHITE#C_VAROUT
	var index := 0
	for i in len(parts):
		if parts[i]:
			_h_var(from, parts[i], index)
			index += 1
		from += len(parts[i]) + 1
	
func _h_node_action(from: int, to: int, color: Color):
	_c(from, C_SYMBOL)
	_c(from+1, color)
	from += 1
	var parts := UString.split_outside(text.substr(from, to-from), " ")
	var clr := color
	var index := 0
	for i in len(parts):
		if parts[i]:
			# function name
			if index == 0:
				clr = color
				_c(from, clr)
				for j in range(from, from+len(parts[i])):
					if text[j] == ".":
						clr = UColor.hue_shift(clr, -.1)
						clr.v += .2
						_c(j, C_SYMBOL)
						_c(j+1, clr)
			
			# arguments
			else:
				_h_var(from, parts[i], index)
			
			index += 1
		
		from += len(parts[i]) + 1
	
func _h_eval(from: int, to: int):
	_c(from, C_SYMBOL)# C_CONTEXT_ACTION)
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
		
		elif text[i] == "^":
			t_color = C_PERSISTENT_ACTION
			m_color = C_PERSISTENT_ACTION
			_c(i, Color(m_color, .5))
			_c(i+1, t_color)
		
		if text[i] == ".":
			t_color = UColor.hue_shift(t_color, -.033)
			_c(i, C_SYMBOL)
			_c(i+1, t_color)
		
		elif text[i] in "0123456789":
			_c(i, Color.WHITE)
		
		elif text[i] == "(":
			_c(i, C_SYMBOL)
			t_color = Color.GRAY
			_c(i+1, t_color)
		
		elif text[i] in "`'\",":
			_c(i, C_SYMBOL)
			t_color = Color.GRAY
			m_color = Color.GRAY
			_c(i+1, t_color)
		
		elif text[i] in "-=+*/<>)()[]{}":
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
	
	var md_tag1 := false # *	_
	var md_tag2 := false # **	__
	var md_tag3 := false # ***	___
#
	var in_predicate := false
	var clr_stack := [default]
	
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
				_c(end+1, clr_stack[-1])
				i = end
		
		# predicate start
		elif text[i] == "(":
			in_predicate = true
			clr_stack[-1].r = C_TEXT_PREDICATE.r
			clr_stack[-1].g = C_TEXT_PREDICATE.g
			clr_stack[-1].b = C_TEXT_PREDICATE.b
			_c(i, C_SYMBOL)
			_c(i+1, clr_stack[-1])
		# predicate end
		elif text[i] == ")":
			in_predicate = false
			_c(i, C_SYMBOL)
			_c(i+1, clr_stack[-1])
		
		# bbcode tags
		elif text[i] == "[":
			var end := text.find("]", i+1)
			var added_color := false
			if end != -1:
				clr_stack.append(clr_stack[-1])
				
				var inner := text.substr(i+1, end-i-1)
				var off = i + 1
				var tags := inner.split(";")
				for tag_index in len(tags):
					var tag := tags[tag_index]
					var tag_to := off + len(tag)
					
					if tag.begins_with("!"):
						tag = tag.substr(1)
						_c(off, C_SYMBOL)
						off += 1
					
					# empty? pop last color tag
					elif tag == "":
						if len(clr_stack) > 1:
							clr_stack.pop_back()
					
					# colorize action tags
					# @node action
					elif tag.begins_with("@"):
						_h_node_action(off, tag_to, C_NODE_ACTION)
					# $state action
					elif tag.begins_with("$"):
						_h_node_action(off, tag_to, C_STATE_ACTION)
					# ^persistent state action
					elif tag.begins_with("^"):
						_h_node_action(off, tag_to, C_PERSISTENT_ACTION)
					# ~ eval
					elif tag.begins_with("~"):
						_h_eval(off, tag_to)
					
					# hacky way of getting bold
					elif tag == "b":
						added_color = true
						clr_stack[-1].a = 4
					
					# dim for italic
					elif tag == "i":
						added_color = true
						clr_stack[-1].r = lerp(clr_stack[-1].r, 1.0, 0.33)
						clr_stack[-1].g = lerp(clr_stack[-1].g, 1.0, 0.33)
						clr_stack[-1].b = lerp(clr_stack[-1].b, 1.0, 0.33)
					
					# hacky way of getting bold
					elif tag == "bi":
						added_color = true
						# bold
						clr_stack[-1].a = 4
						# italics
						clr_stack[-1].r = lerp(clr_stack[-1].r, 1.0, 0.33)
						clr_stack[-1].g = lerp(clr_stack[-1].g, 1.0, 0.33)
						clr_stack[-1].b = lerp(clr_stack[-1].b, 1.0, 0.33)
					
					# color?
					else:
						var tag_clr = UStringConvert.to_color(tag, null)
						if tag_clr != null:
							added_color = true
							clr_stack[-1].r = tag_clr.r
							clr_stack[-1].g = tag_clr.g
							clr_stack[-1].b = tag_clr.b
						
						# must be a normal tag
						else:
							_c(off, C_TAG)
					
					off += len(tag)
					_c(off, C_SYMBOL) # colorize ; seperator
					off += 1
				
				if not added_color and len(clr_stack) > 1:
					clr_stack.pop_back()
				
				# colorize open and close tags
				_c(i, C_SYMBOL) 	# [ open
				_c(end, C_SYMBOL)	# ] close
				# back to normal text color
				_c(end+1, clr_stack[-1])
				
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
			_c(i, clr_stack[-1])
		
		# markdown: * ** ***
		elif text[i] == "*":
			_c(i, C_SYMBOL)
			i += 1
			if i < len(text) and text[i] == "*":
				i += 1
				if i < len(text) and text[i] == "*":
					i += 1
					# bold italic
					md_tag3 = not md_tag3
					clr_stack[-1].a = 4 if md_tag3 or md_tag2 else 1
					_c(i, clr_stack[-1])# clr_stack[-1] if md_tag3 else default)
				else:
					# bold
					md_tag2 = not md_tag2
					clr_stack[-1].a = 4 if md_tag3 or md_tag2 else 1
					_c(i, clr_stack[-1] if md_tag2 else default)
			else:
				# italic
				md_tag1 = not md_tag1
				clr_stack[-1].a = 0.8 if md_tag1 else 1
				_c(i, clr_stack[-1] if md_tag1 else default)
		
		elif text[i] == "_":
			_c(i, C_SYMBOL)
			i += 1
			if i < len(text) and text[i] == "_":
				i += 1
				if i < len(text) and text[i] == "_":
					i += 1
					# bold italic
					md_tag3 = not md_tag3
					clr_stack[-1].a = 4 if md_tag3 or md_tag2 else 1
					_c(i, clr_stack[-1] if md_tag3 else default)
				else:
					# bold
					md_tag2 = not md_tag2
					clr_stack[-1].a = 4 if md_tag3 or md_tag2 else 1
					_c(i, clr_stack[-1] if md_tag2 else default)
			else:
				# italic
				md_tag1 = not md_tag1
				clr_stack[-1].a = 0.8 if md_tag1 else 1
				_c(i, clr_stack[-1] if md_tag1 else default)
		i += 1

func get_flow_color(deep: int) -> Color:
	var color := UColor.hue_shift(C_FLOW, .3 * deep)
	color.v -= .15 * deep
	return color

func _h_flow(from: int, to: int):
	var inner := text.substr(from, to-from)
	var true_deep = _find_true_depth()+1
	
	_c(from, C_SYMBOL)
	_c(from+2, get_flow_color(true_deep))
	from += 2
	
	var started := false
	var path_deep := true_deep
	for i in range(from, to):
		# nested path?
		if text[i] == ".":
			if not started:
				started = true
				path_deep = true_deep-1
			else:
				path_deep -= 1
			_c(i, C_SYMBOL)
			_c(i+1, get_flow_color(path_deep))
		
		# subpath?
		elif text[i] == "/":
			if not started:
				path_deep = 0
				started = true
			else:
				path_deep += 1
			_c(i, C_SYMBOL)
			_c(i+1, get_flow_color(path_deep))
		
		if not text[i] in " \t":
			started = true

func _h_properties(from: int, to: int):
	var parts := text.substr(from, to-from).split(" ")
	for i in len(parts):
		_h_var(from, parts[i], i)
		from += len(parts[i]) + 1

func _h_line(from: int, to: int):
	var comment := text.find("# ", from)
	if comment != -1 and comment < to:
		to = comment
	
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
		_c(to+1, C_SYMBOL) # || divider
		
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
			_h_node_action(from, to, C_NODE_ACTION)
		# $state action
		elif part.begins_with("$"):
			_h_node_action(from, to, C_STATE_ACTION)
		# ^persistent state action
		elif part.begins_with("^"):
			_h_node_action(from, to, C_PERSISTENT_ACTION)
		# ~ eval
		elif part.begins_with("~"):
			_h_eval(from, to)
		
		# options
		elif part.begins_with(Soot.CHOICE):
			_c(from, Color(C_OPTION_TEXT, .5))
			_c(from+len(Soot.CHOICE), C_OPTION_TEXT)
			_h_bbcode(from+len(Soot.CHOICE), to, C_OPTION_TEXT)
#			_h_flow(from, to)
		
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
			_h_flow(from, to)
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
				var sub = text.substr(from, i-from)
				# colorize in brackets
				if "(" in sub:
					var a := sub.find("(")
					var b := sub.rfind(")")
					_c(from+a, C_SYMBOL)
					_c(from+a+1, C_NODE_ACTION)
					_c(from+b, C_SYMBOL)
				_c(from+i+1, C_TEXT)
				from = i+1
			
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
