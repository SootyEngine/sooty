@tool
extends SyntaxHighlighter

const C_PROPERTY := Color.TAN
const C_SYMBOL := Color(1, 1, 1, 0.25)
const C_SYMBOL_LIGHT := Color(1, 1, 1, 0.4)
const C_FIELD := Color.LIGHT_GRAY
const C_OBJECT := Color.GREEN_YELLOW
const C_LIST_ITEM := Color.SPRING_GREEN

const C_SHORTCUT_PROPERTY := Color.DEEP_SKY_BLUE
const C_SHORTCUT_FIELD := Color.DEEP_PINK

const C_ERROR := Color.TOMATO

var _out := {}
var _text := ""
var _deep := 0

func _c(i: int, clr: Color):
	_out[i] = { color=clr }

func _hl_dict(from: int) -> int:
	var a := _text.find("{", from)
	if a != -1:
		_c(a, C_SYMBOL)
		var b := _text.find("}", a+1)
		if b != -1:
			_c(b, C_SYMBOL)
			var inner := _text.substr(a+1, b-a-1)
			var off = a+1
			for part in inner.split(","):
				var i := part.find(":")
				if i != -1:
					var c := C_PROPERTY.darkened((_deep+1) * .05)
					c.h = wrapf(c.h - .2 * (_deep+1), 0.0, 1.0)
					_c(off, c)
					_c(off+i, C_SYMBOL)
					_c(off+i+1, C_FIELD)
				else:
					# dict key needed
					_c(off, C_ERROR)
				# comma
				_c(off+len(part), C_SYMBOL)
				off += len(part)+1
		return b+1
	return -1

func _hl_list(from: int) -> int:
	var a := _text.find("[", from)
	if a != -1:
		_c(a, C_SYMBOL)
		var b := _text.find("]", a+1)
		if b != -1:
			_c(b, C_SYMBOL)
			var inner := _text.substr(a+1, b-a-1)
			var off = a+1
			for part in inner.split(","):
				var i := part.find(":")
				if i != -1:
					var c := C_PROPERTY.darkened((_deep+1) * .05)
					c.h = wrapf(c.h - .2 * (_deep+1), 0.0, 1.0)
					_c(off, c)
					_c(off+i, C_SYMBOL)
					_c(off+i+1, C_FIELD)
				else:
					_c(off, C_FIELD)
				# comma
				_c(off+len(part), C_SYMBOL)
				off += len(part)+1
		return b+1
	return -1

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	return _get_line_syntax_highlighting2(get_text_edit().get_line(line))

func _get_line_syntax_highlighting2(text: String) -> Dictionary:
	_out = {}
	_text = text
	_deep = UString.count_leading_tabs(text)
	
	# shortcuts
	if _text.begins_with("~~"):
		_c(0, C_SYMBOL)
		_c(2, C_SHORTCUT_PROPERTY)
		var clr = C_PROPERTY
		var deep := 0
		for i in range(3, len(_text)):
			if _text[i] == ":":
				_c(i, C_SYMBOL)
				_c(i+1, clr)
				deep += 1
				clr = C_PROPERTY.darkened(deep * .05)
				clr.h = wrapf(clr.h - .2 * deep, 0.0, 1.0)
				
			elif _text[i] == ".":
				_c(i, C_SYMBOL)
				_c(i+1, clr)
				deep += 1
				clr = C_PROPERTY.darkened(deep * .05)
				clr.h = wrapf(clr.h - .2 * deep, 0.0, 1.0)
			
		return _out
	
	var stripped = _text.strip_edges()
	var i := 0
	
	# list item
	if stripped.begins_with("- ") or stripped == "-":
		i = _text.find("-")
		_c(i, C_LIST_ITEM)
		_c(i+1, C_FIELD)
		i += 2
	else:
		# start as a field, for multiline
		_c(0, C_FIELD)
	
	# property name `:`
	var a := _find_property_split(_text, i)
	if a != -1:
		var c := C_PROPERTY.darkened(_deep * .05)
		c.h = wrapf(c.h - .2 * _deep, 0.0, 1.0)
		_c(i, c)#C_PROPERTY.darkened(_deep * .2))
		_c(a, C_SYMBOL)
		_c(a+1, C_FIELD)
		
		# object initializer
		for j in range(i, a):
			match _text[j]:
				"=":
					_c(j, C_SYMBOL)
					_c(j+1, C_OBJECT)
				"?":
					_c(j, C_SYMBOL)
					_c(j+1, Color.TOMATO)
#		var e = _text.find("=", i)
#		if e != -1 and e < a:
#		else:
#			# flag
#			e = _text.find("?", i)
#			if e != -1 and e < a:
#				_c(e, C_SYMBOL)
#				_c(e+1, Color.TOMATO)
		
		i = a + 1
	
	# multiline tag `""""`
	a = _text.find('""""', i)
	if a != -1:
		_c(a, C_SYMBOL)
		i = a + 4
	
	# dict
	a = _hl_dict(i)
	if a != -1:
		i = a
	
	# list
	a = _hl_list(i)
	if a != -1:
		i = a
	
	# comment
	a = _text.find("# ", 0)
	if a != -1:
		_c(a, C_SYMBOL)
		for k in _out.keys():
			if k > a:
				_out.erase(k)
	
	return _out

func _find_property_split(text: String, from: int) -> int:
	for i in range(from, len(text)):
		match text[i]:
			"{", "[": break
			":":
				if (i == len(text)-1 or text[i+1] in " \n\t"):
					return i
	return -1
