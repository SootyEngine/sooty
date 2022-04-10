@tool
extends EditorSyntaxHighlighter

func _get_name() -> String:
	return "Soot"

# operators
const OP_RELATIONS := ["==", "!=", "<", "<=", ">", ">="]
const OP_ASSIGNMENTS := ["=", "+=", "-="]
const OP_EVALS := ["if", "elif", "else", "match", "rand"]
const OP_KEYWORDS := ["and", "or", "not"]
const OP_ALL := OP_RELATIONS + OP_ASSIGNMENTS + OP_EVALS + OP_KEYWORDS

const SYMBOL_ALPHA := .5

# colors
const C_TEXT := Color.GAINSBORO
const C_TEXT_INSERT := Color.PALE_GREEN
const C_SPEAKER := Color(1, 1, 1, 0.5)
const C_TAG := Color(1, 1, 1, .5)
const C_SYMBOL := Color(1, 1, 1, 0.33)

const C_FLAG := Color.SALMON
const C_LANG := Color.YELLOW_GREEN

const C_COMMENT := Color(1.0, 1.0, 1.0, 0.25)
const C_COMMENT_LANG := Color(0.5, 1.0, 0.0, 0.5)

const C_NODE_ACTION := Color.DEEP_SKY_BLUE
const C_STATE_ACTION := Color.ORCHID
const C_EVAL := Color.LIGHT_GREEN
const C_EVAL_TAG := Color(0, 1, 0.5, 0.8*.5)
const C_COMMAND := Color.GOLD
const C_VAR_SHORTCUT := Color.CADET_BLUE

const C_FLOW := Color.WHEAT
const C_FLOW_GOTO := Color.TAN
const C_FLOW_CALL := Color.TAN
const C_FLOW_END := Color.TOMATO

const C_OPTION_FLAG := Color(0.25, 0.88, 0.82, 0.5)
const C_OPTION_TEXT := Color.WHEAT

# strings
const S_FLAG := "\t#?"
const S_BLOCK_SEPERATOR := "---"

#const S_PROPERTY := "-"
const S_OPTION := ">>>"# "|>"
const S_OPTION_ADD := "+>"

const S_TEXT_INSERT := "&"

const S_EVAL := "~"
const S_STATE_ACTION := "$"
const S_NODE_ACTION := "@"
const S_COMMAND := ">"
const S_VAROUT := "*"

const S_FLATLINE := "||"

const S_LIST_START := "{["
const S_LIST_END := "]}"
const S_COND_START := "{{"
const S_COND_END := "}}"

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
	
	# new document
	elif text.begins_with(S_BLOCK_SEPERATOR):
		_c(0, Color.ORANGE)
	
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
#		var to = _h_flatline(C_TEXT, from)
		
		# flow
		if text.begins_with(Soot.FLOW):
			_c(0, C_SYMBOL)
			_c(len(Soot.FLOW), C_FLOW)
		
		else:
			# condition
#			var a := text.find(S_COND_START)
#			var b := text.rfind(S_COND_END)
#			var f := from
#			if a != -1 and b != -1:
#				_c(a, C_SYMBOL)
#				_c(b, C_SYMBOL)
#				_c(b+len(S_COND_END), C_TEXT)
#				_h_conditional(a+len(S_COND_START), b-1)
#				f = b+len(S_COND_END)
#
#				# highlight line before conditional
#				_h_line(from, a)
#
#				# highlight line after conditional, in case of 'match'
#				_h_line(f, to if to>0 else len(text))
			
#			else:
			if text.strip_edges().begins_with(S_TEXT_INSERT):
				from = text.find(S_TEXT_INSERT, from)
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

func _set_var_color(from: int, v: String, is_action := false, index := 0, action_color := Color.WHITE):
#	if (is_action and index == 0) or v[0] == "*":
#		_c(from, Color(action_color, SYMBOL_ALPHA))
	if not len(v):
		return
	
	if is_action and index == 0:
		_c(from, Color(action_color, SYMBOL_ALPHA))
		# only highlight last part
		var d := v.rfind(".")
		if d != -1:
			_c(from+1, action_color.darkened(.25))
			_c(from+1+d, action_color)
		else:
			_c(from+1, action_color)
	
	elif UString.is_wrapped(v, "<<", ">>"):
		_c(from, C_EVAL_TAG)
		_c(from+2, C_EVAL)
		_c(from+len(v)-2, C_EVAL_TAG)
	
	# dict key
	elif ":" in v:
		var p := v.split(":", true, 1)
#		_c(from, C_SYMBOL)
		_c(from, Color(action_color, .75))
		_c(from+len(p[0]), C_SYMBOL)
		_set_var_color(from+len(p[0])+1, p[1], false, 0, action_color)
	
	# array
	elif "," in v:
		var off := from
		var parts := v.split(",")
		for i in len(parts):
			var part := parts[i]
			_set_var_color(off, part, false, index, action_color)
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
			
		var clr := action_color
		clr.h = wrapf(clr.h - .05, 0.0, 1.0)
		if index % 2 != 0:
			clr = clr.lightened(.77)
		else:
			clr = clr.lightened(.22)
		_c(from, clr)
	

func _h_action(from: int, to: int):
	_c(from, C_SYMBOL)
	var inner := text.substr(from, to-from)
	
	if not len(inner):
		return
	
	var color = C_EVAL
	var index := 0
	
	if inner.begins_with(S_NODE_ACTION):
		color = C_NODE_ACTION
	elif inner.begins_with(S_STATE_ACTION):
		color = C_STATE_ACTION
	elif inner.begins_with(S_COMMAND):
		color = C_COMMAND
	elif inner.begins_with("*"):
		color = C_VAR_SHORTCUT
		index += 2
	else:
		_h_eval(from, to)
		return
	
	var parts = UString.split_outside(inner, " ")
	for part in parts:
		_set_var_color(from, part, true, index, color)
		if index == 0 and len(part) == 1:
			pass
		else:
			index += 1
		from += len(part) + 1

func _h_eval(from: int, to: int):
	if text[from] == S_EVAL:
		_c(from, Color(C_EVAL, SYMBOL_ALPHA))
		_c(from+1, C_EVAL)
	else:
		_c(from, C_EVAL)
#	for i in range(from+1, to):
#		if text[i] in ",.[](){}\"'-+=<>":
#			_c(i, C_SYMBOL)
#			_c(i+1, C_EVAL)

func _h_conditional(from: int, to: int, begins_with: bool):
	var inner := text.substr(from, to-from)
	var off := from
	
	for k in ["IF ", "ELIF ", "ELSE", "MATCH "]:
		if inner.begins_with(k):
			_c(from, C_SYMBOL)
			inner = inner.trim_prefix(k)
			from += len(k)
			break
	
	var meta_actions := UString.split_outside(inner, " OR ")
	for i in len(meta_actions):
		var actions := UString.split_outside(meta_actions[i], " AND ")
		for j in len(actions):
			_h_action(from, from + len(actions[j]))
			from += len(actions[j])
			if j < len(actions)-1:
				_c(from, C_SYMBOL)
				from += len(" AND ")
		if i < len(meta_actions)-1:
			_c(from, C_SYMBOL)
			from += len(" OR ")

func _h_bbcode(from: int, to: int, default: Color):
	var i := from
	while i < to:
		if text[i] == "#":
			break
		elif text[i] == "{":# and (i != 0 and text[i-1] != "#"):
			var end := text.find("}", i+1)
			if end != -1:
				# colorize open and close tags
				_c(i, C_SYMBOL)
				_h_text_feature(i+1, end, default)
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
					if tag.begins_with(S_EVAL):
						_h_action(off, off+len(tag))
#					elif tag.begins_with(S_ACTION_NODE):
#						_h_action(off, off+len(tag), C_ACTION_NODE)
					elif tag.begins_with(S_NODE_ACTION):
						_h_action(off, off+len(tag))
					elif tag.begins_with(S_STATE_ACTION):
						_h_action(off, off+len(tag))
					# colorize normal tags
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
		
		elif text[i] == "&":
			_c(i, C_SYMBOL)
			_c(i+1, C_TEXT_INSERT)
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
			var lit = tag[1]
			_c(j, C_SYMBOL)
			j += len(tag[0])
			# path divider exists?
			var d := text.find(Soot.FLOW_PATH_DIVIDER, j)
			if d != -1:
				# darken head of the path
				_c(j, lit.darkened(.33))
				j = d+1
			# colorize path
			_c(j, lit)
			j += len(tag[0])
			i = j

func _h_properties(from: int, to: int):
	for part in text.substr(from, to-from).split(" "):
		_set_var_color(from, part)
		from += len(part) + 1

func _h_line(from: int, to: int):
	var t := text.substr(from, to-from)
	var len_old = len(t)
	t = t.strip_edges(true, false)
	from += len_old - len(t)
	t = t.strip_edges(false, true)
	
	var parts := t.split(S_FLATLINE)
	
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
			
			var e := part.find(S_COND_END)
			if e != -1:
				to = from + e
				# tail tag }}
#				_c(to, C_EVAL_TAG)
				_c(to, C_SYMBOL)
				# condition
				_h_conditional(from + len(S_COND_START), to, true)
				from += e + len(S_COND_END) + 1
				to = next_from-2
				part = text.substr(from, to-from)
			else:
				part = ""
		# line ending with a condition.
		elif part.ends_with(S_COND_END):
			var s := part.rfind(S_COND_START, to)
			if s != -1:
				_c(from+s, C_SYMBOL)
				_h_conditional(from+s + len(S_COND_START), to - len(S_COND_END), false)
				to = from+s
				part = text.substr(from, to-from)
			_c(to-len(S_COND_END), C_SYMBOL) # }} symbol
		
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
		
		# $state actions
		elif part.begins_with(S_STATE_ACTION):
			_h_action(from, to)
		# @node actions
		elif part.begins_with(S_NODE_ACTION):
			_h_action(from, to)
		# > commands
		elif part.begins_with(S_COMMAND):
			_h_action(from, to)
		# *var
		elif part.begins_with(S_VAROUT):
			_h_action(from, to)
		
		# ~evals
		elif part.begins_with(S_EVAL):
			_h_eval(from, to)
		
		# options
		elif part.begins_with(S_OPTION):
			_c(from, Color(C_OPTION_TEXT, .5))
			_c(from+len(S_OPTION), C_OPTION_TEXT)
			_h_bbcode(from+len(S_OPTION), to, C_OPTION_TEXT)
			_h_flow()
		
		# options: add
		elif part.begins_with(S_OPTION_ADD):
			var c_option_add = C_OPTION_TEXT
			c_option_add.h = wrapf(c_option_add.h - .22, 0.0, 1.0)
			c_option_add.v = clampf(c_option_add.v - 0.25, 0.0, 1.0)
			_c(from, C_SYMBOL)
			_c(from+len(S_OPTION_ADD), c_option_add)
			var s := text.find("*", from+len(S_OPTION_ADD))
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

func _h_text_feature(from: int, to: int, text_color: Color):
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
