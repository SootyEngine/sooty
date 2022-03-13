@tool
extends EditorSyntaxHighlighter

func _get_name() -> String:
	return "Soot"

# operators
const OP_RELATIONS := ["==", "!=", "<", "<=", ">", ">="]
const OP_ASSIGNMENTS := ["=", "+=", "-="]
const OP_ALL := OP_RELATIONS + OP_ASSIGNMENTS

# colors
const C_TEXT := Color.GAINSBORO
const C_SPEAKER := Color(1, 1, 1, 0.4)#Color(0.0, 1.0, 1.0, 0.5)
const C_TAG := Color(1, 1, 1, .5)
const C_SYMBOL := Color(1, 1, 1, 0.25)

const C_PROPERTY := Color(1, 1, 1, .25)
const C_VAR_BOOL := Color.PALE_GOLDENROD
const C_VAR_FLOAT := Color.ORANGE
const C_VAR_INT := Color.ORANGE
const C_VAR_STR := Color.SANDY_BROWN
const C_VAR_UNKOWN := Color.PALE_GOLDENROD
const C_VAR_CONSTANT := Color.DARK_GRAY
const C_VAR_STATE_PROPERTY := Color.SPRING_GREEN

const C_FUNCTION := Color.MEDIUM_PURPLE

const C_COMMENT := Color(1.0, 1.0, 1.0, 0.25)
const C_FE_TAG := Color.PALE_VIOLET_RED
const C_ACTION := Color.RED
const C_ACTION_ASSIGN := Color.PALE_VIOLET_RED

const C_FLOW := Color.GREEN_YELLOW
const C_FLOW_GOTO := Color.GREEN_YELLOW
const C_FLOW_CALL := Color.DEEP_SKY_BLUE

const C_CONDITION := Color.WHEAT
const C_OPTION_FLAG := Color(0.25, 0.88, 0.82, 0.5)
const C_OPTION_TEXT := Color.TURQUOISE

# strings
const S_FLOW := "==="
const S_FLOW_GOTO := "=>"
const S_FLOW_CALL := "=="
const S_ACTION := "~"
const S_COMMENT := "//"
const S_PROPERTY := "|"
const S_OPTION_START := "<"
const S_OPTION_END := ">"
const S_FLATLINE_START := "(("
const S_FLATLINE_END := "))"
const S_COND_START := "{{"
const S_COND_END := "}}"

var index := 0
var state := {}
var text := ""

func _co(clr: Color, offset := 0):
	state[index] = {color=clr}
	index += offset

func _c(i: int, clr: Color, offset := 0):
	index = i
	_co(clr, offset)

func _set_var_color(i: int, v: String, is_function := false):
	if " " in v:
		var off := i
		for part in v.split(" "):
			_set_var_color(off, part)
			off += len(part) + 1
	# dict key
	elif ":" in v:
		var p := v.split(":", true, 1)
		_c(i, C_PROPERTY)
		_c(i+len(p[0]), C_SYMBOL)
		_set_var_color(i+len(p[0])+1, p[1])
	# array
	elif "," in v:
		var off := i
		for part in v.split(","):
			_set_var_color(off, part)
			off += len(part)
			state[off] = {color=C_SYMBOL}
			off += 1
	# match "default"
	elif v in ["_", "==", "!=", "=", "+=", "-=", ">", ">=", "<", "<="]:
		_c(i, C_SYMBOL)
	# state property
	elif v.begins_with("$"):
		# only highlight last part
		var d := v.rfind(".")
		_c(i, C_VAR_STATE_PROPERTY.darkened(.4))
		if d != -1:
			_c(i+d+1, C_VAR_STATE_PROPERTY)
		else:
			_c(i+1, C_VAR_STATE_PROPERTY)
	elif is_function:
		# only highlight last part
		var d := v.rfind(".")
		_c(i, C_FUNCTION.darkened(.4))
		if d != -1:
			_c(i+d, C_FUNCTION)
		else:
			_c(i, C_FUNCTION)
	elif v.is_valid_int():
		_c(i, C_VAR_INT)
	elif v.is_valid_float():
		_c(i, C_VAR_FLOAT)
	elif v in ["true", "false", "null"]:
		_c(i, C_VAR_BOOL)
	elif v == v.to_upper():
		_c(i, C_VAR_CONSTANT)
	else:
		_c(i, C_VAR_STR)

func _h_action(from: int, to: int):
	_c(from, C_SYMBOL)
	var inner := text.substr(from+1, to-from-1)
	var parts := StringAction.split_string(inner)
	var off := from+1
	for i in len(parts):
		var part = parts[i]
		_set_var_color(off, part, i == 0)
		off += len(part) + 1

func _h_conditional(from: int, to: int):
	var off := from
	var parts = Array(text.substr(from, to-from+1).split(" "))
	
	if parts[0] in ["if", "elif", "else", "match"]:
		var part = parts.pop_front()
		_c(off, C_SYMBOL)
		off += len(part)+1
	
	var is_assign = len(parts)==3 and parts[1] in OP_ALL
	var is_match := false
	
	for i in len(parts):
		var part = parts[i]
		
		# match
		if part.begins_with("*"):
			part = part.substr(1)
			state[off] = { color=C_SYMBOL }
			is_match = true
			off += 1
		
		_set_var_color(off, part)
		off += len(part) + 1

func _h_flatline(default: Color, from: int):
	var i := text.find(S_FLATLINE_START, from)
	if i != -1:
		var j := text.find(S_FLATLINE_END, i+len(S_FLATLINE_START))
		if j != -1:
			var inner := text.substr(i+len(S_FLATLINE_START), j-i-len(S_FLATLINE_START))
			var off := i+len(S_FLATLINE_START)
			for part in inner.split(";;"):
				_h_line(off, off+len(part))
				off += len(part)
				_c(off, C_SYMBOL)
				off += len(";;")
			
			# opening symbol
			_c(i, C_SYMBOL, len(S_FLATLINE_START))
			# closing symbol
			_c(j, C_SYMBOL, len(S_FLATLINE_END))
	return i
	
func _h_bbcode(from: int, to: int, default: Color):
	var i := from
	while i < to:
		if text[i] == "[":
			var b := text.find("]", i+1)
			if b != -1:
				var inner := text.substr(i+1, b-i-1)
				var off = i + 1
				for tag in inner.split(";"):
					# colorize action tags
					if tag.begins_with("~"):
						_h_action(off+1, off+len(tag))
					# colorize normal tags
					else:
						_c(off, C_TAG)
					off += len(tag)
					# colorize ; seperator
					_c(off, C_SYMBOL)
					off += 1
				# colorize open and close tags
				_c(i, C_SYMBOL)
				_c(b, C_SYMBOL)
				# back to normal text color
				_c(b+1, default)
				i = b
		i += 1

func _h_flow(from := 0):
	# => and ==
	for tag in [[S_FLOW_GOTO, C_FLOW_GOTO], [S_FLOW_CALL, C_FLOW_CALL]]:
		var i := from
		while true:
			var j := text.find(tag[0], i)
			if j == -1:
				break
			var lit = tag[1]
			var drk = tag[1]
			drk.a = .5
			_c(j, drk, len(tag[0]))
			_co(lit)
			i = j + len(tag[0])

func _h_line(from: int, to: int):
	var t := text.substr(from, to-from).strip_edges()
	
	# properties
	if t.begins_with(S_PROPERTY):
		var i := text.find(S_PROPERTY, from)
		var j := i + len(S_PROPERTY)
		_c(i, C_SYMBOL)
		_set_var_color(j, text.substr(j))
	
	# action
	elif t.begins_with(S_ACTION):
		_h_action(text.find(S_ACTION, from), to)
	
	# options
	elif t.begins_with(S_OPTION_START):
		var s := text.find(S_OPTION_START)
		var e := text.find(S_OPTION_END)
		_c(s, C_SYMBOL, 1)
		_c(s+1, C_OPTION_FLAG)
		_c(e, C_SYMBOL, 1)
		_co(C_OPTION_TEXT)
		_h_bbcode(e+1, to, C_OPTION_TEXT)
		_h_flow()
	
	elif t.begins_with(S_FLOW_GOTO) or t.begins_with(S_FLOW_CALL):
		_h_flow()
	
	else:
		# text
		if ":" in text:
			var i := text.find(":", from)
			_c(max(from, text.rfind(" ", i)), C_SPEAKER)
			_c(i, C_SYMBOL, 1)
			_co(C_TEXT)
		
		_h_bbcode(from, to, C_TEXT)

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	text = get_text_edit().get_line(line)
	state = {}
	index = 0
	_c(0, C_TEXT)
	var stripped = text.strip_edges()
	var out = state
	
	var to := _h_flatline(C_TEXT, 0)
	
	# flow
	if text.begins_with(S_FLOW):
		_c(0, C_SYMBOL)
		_c(len(S_FLOW), C_FLOW)
	
	else:
		# condition
		var a := text.find(S_COND_START)
		var b := text.rfind(S_COND_END)
		var from := 0
		if a != -1 and b != -1:
			_c(a, C_SYMBOL)
			_c(b, C_SYMBOL, len(S_COND_END))
			_h_conditional(a+len(S_COND_START), b-1)
			from = b+len(S_COND_END)
		
		_h_line(from, to if to>0 else len(text))
		
		var f := text.find('""""')
		if f != -1:
			_c(f, C_SYMBOL)
	
	# comments
	index = text.find(S_COMMENT)
	if index != -1:
		_co(C_COMMENT)
		# erase all colors afterwards
		for k in state.keys():
			if k > index:
				state.erase(k)
	
	return state
