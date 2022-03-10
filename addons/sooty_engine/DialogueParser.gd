@tool
extends Resource
class_name DialogueParser

const DEBUG_KEEP_DICTS := false
const REWRITE := 6

static func parse(file: String) -> Dictionary:
	var text_lines := UFile.load_text(file).split("\n")
	var dict_lines := []
	
	# Convert text lines to dict lines.
	for i in len(text_lines):
		var stripped := text_lines[i]
		# remove comment
		if "//" in stripped:
			stripped = stripped.split("//", true, 1)[0]
		stripped = stripped.strip_edges()
		
		# ignore empty lines
		if len(stripped):
			var did: String = file.get_file().split(".", true, 1)[0]
			dict_lines.append({
				did=did,
				file=0,
				line=i,
				type="_",
				text=stripped,
				deep=_count_leading_tabs(text_lines[i]),
				tabbed=[]
			})
	
	# Collect tabs, recursively.
	var i := 0
	var new_list := []
	while i < len(dict_lines):
		var o = _collect_tabbed(dict_lines, i)
		i = o[0]
		new_list.append(o[1])
	
	var out_flows := {}
	var out_lines := {}
	for i in len(new_list):
		match new_list[i].type:
			"flow":
				out_flows[new_list[i].text] = new_list[i]
				_clean(new_list[i], out_lines)
	
	return { flows=out_flows, lines=out_lines }

static func _clean_array(lines: Array, all_lines: Dictionary):
	for i in len(lines):
		if DEBUG_KEEP_DICTS: # DEBUG SANITY
			_clean(lines[i], all_lines)
		else:
			lines[i] = _clean(lines[i], all_lines)

static func _clean_nested_array(lines_list: Array, all_lines: Dictionary):
	for i in len(lines_list):
		_clean_array(lines_list[i], all_lines)

static func _clean(line: Dictionary, all_lines: Dictionary) -> String:
	var id := "%s!%s" % [line.file, line.line]
	if not DEBUG_KEEP_DICTS:
		_erase(line, ["did", "deep", "tabbed", "file", "line"])
	match line.type:
		"flow":
			_clean_array(line.then, all_lines)
			_erase(line, ["text"])
			return id
		
		"option":
			if not len(line.flag):
				line.erase("flag")
			if line.then:
				_clean_array(line.then, all_lines)
			else:
				line.erase("then")
			_erase(line, ["text"])
		"goto", "call":
			_erase(line, ["text"])
		"text":
			if "options" in line:
				_clean_array(line.options, all_lines)
		"action":
			_erase(line, ["text"])
		"cond":
			match line.cond_type:
				"if": _clean_nested_array(line.cond_lines, all_lines)
				"match": _clean_nested_array(line.case_lines, all_lines)
			line.type = line.cond_type
			_erase(line, ["text", "cond", "cond_type"])
		_: pass
	
	all_lines[id] = line
	return id

static func _collect_tabbed(dict_lines: Array, i: int) -> Array:
	var line = dict_lines[i]
	_extract_properties(line)
	i += 1
	# collect tabbed
	while i < len(dict_lines) and dict_lines[i].deep > line.deep:
		var o = _collect_tabbed(dict_lines, i)
		line.tabbed.append(o[1])
		i = o[0]
		
	# get properties
	for j in range(len(line.tabbed)-1, -1, -1):
		if line.tabbed[j].type == "prop":
			var props: Dictionary = line.tabbed[j].prop
			if not "prop" in line:
				line.prop = props
			else:
				for k in props:
					line.prop[k] = props[k]
			line.tabbed.remove_at(j)

	# combine if-elif-else
	var new_tabbed := []
	for j in len(line.tabbed):
		var ln: Dictionary = line.tabbed[j]
		match ln.type:
			"cond":
				match ln.cond_type:
					"if", "match":
						new_tabbed.append(ln)
					"elif", "else":
						if j != 0:
							var prev: Dictionary = line.tabbed[j-1]
							if prev.type == "cond" and prev.cond_type == "if":
								prev.conds.append(ln.cond)
								prev.cond_lines.append(ln.tabbed)
						else:
							push_error("'%s' must follow an 'if'." % [ln.cond_type])
			_:
				new_tabbed.append(ln)
	line.tabbed = new_tabbed

	_process_line(line)
	return [i, line]

static func _process_line(line: Dictionary):
	var t: String = line.text
	if t.begins_with("==="): return _line_as_flow(line)
	if t.begins_with("{{"): return _line_as_condition(line)
	_extract_conditional(line)
	if t.begins_with("<"): return _line_as_option(line)
	if t.begins_with("@"): return _line_as_action(line)
	if t.begins_with(">>"): return _line_as_goto(line)
	if t.begins_with("::"): return _line_as_call(line)
	if t.begins_with("|"): return _line_as_properties(line)
	return _line_as_dialogue(line)

static func _line_as_condition(line: Dictionary):
	line.type = "cond"
	line.cond_type = "if"
	_extract_conditional(line)
	
	var cond: String = line.cond
	
	# if-elif-else condition
	if cond.begins_with("if "):
		line.cond_type = "if"
		line.cond = cond.substr(len("if ")).strip_edges()
	elif cond.begins_with("elif "):
		line.cond_type = "elif"
		line.cond = cond.substr(len("elif ")).strip_edges()
	elif cond == "else":
		line.cond_type = "else"
		line.cond = "true"
	
	# match condition
	elif cond.begins_with("*"):
		line.cond_type = "match"
		line.match = line.cond.substr(1)
		line.cases = []
		line.case_lines = []
		for tabbed_line in line.tabbed:
			if tabbed_line.type == "cond":
				line.cases.append(tabbed_line.cond)
				line.case_lines.append(tabbed_line.tabbed)
				
				# treat as an unprocessed line now.
				# and then add it to the front of it's list.
				if tabbed_line.text.strip_edges() != "":
					_erase(tabbed_line, ["cond", "cond_type", "conds", "cond_lines"])
					tabbed_line.tabbed = []
					_process_line(tabbed_line)
					line.case_lines[-1].push_front(tabbed_line)
	
	if line.cond_type == "if":
		line.conds = [line.cond]
		line.cond_lines = [line.tabbed]

static func _line_as_option(line: Dictionary):
	var t: String = line.text
	var a := t.find("<")
	var b := t.find(">", a)
	
	line.type = "option"
	line.text = t.substr(b+1).strip_edges()
	line.flag = t.substr(a+1, b-a-1).strip_edges()
	
	_extract_action(line)
	
	# extract flow lines
	var lines := []
	for li in line.tabbed:
		match li.type:
			_: lines.append(li)
	
	var p := _trailing_tokens(line.text, [">>", "::", "@"])
	line.text = p[0]
	for t in p[1]:
		var token: String = t[0]
		var t_str: String = t[1]
		match token:
			">>": lines.append(_add_flow_action({did=line.did, file=line.file, line=line.line}, "call", t_str))
			"::": lines.append(_add_flow_action({did=line.did, file=line.file, line=line.line}, "goto", t_str))
			"@" : lines.append({file=line.file, line=line.line, type="action", action=t_str })
	
	line.then = lines

static func _line_as_goto(line: Dictionary):
	var p = line.text.rsplit(">>", true, 1)
	line.text = p[0].strip_edges()
	_add_flow_action(line, "goto", p[1].strip_edges())

static func _line_as_call(line: Dictionary):
	var p = line.text.split("::", true, 1)
	line.text = p[0].strip_edges()
	_add_flow_action(line, "call", p[1].strip_edges())

static func _add_flow_action(line: Dictionary, type: String, f_action: String):
	line.type = type
	line[type] = f_action if "." in f_action else "%s.%s" % [line.did, f_action]
	return line
	
static func _line_as_action(line: Dictionary):
	line.type = "action"
	line.action = line.text.substr(len("@"))
	
static func _line_as_properties(line: Dictionary):
	var properties := {}
	for prop in line.text.substr(len("|")).split(" "):
		var p = prop.split(":", true, 1)
		properties[p[0]] = p[1]
	line.type = "prop"
	line.prop = properties

static func _line_as_flow(line: Dictionary):
	line.type = "flow"
	line.text = line.text.substr(len("===")).strip_edges()
	line.then = line.tabbed

static func _line_as_dialogue(line: Dictionary):
	var text: String = line.text
	line.type = "text"
	if ":" in text:
		var p := text.split(":", true, 1)
		line.from = p[0].strip_edges()
		line.text = p[1].strip_edges()
	
	var options := []
	var lines := []
	for tabbed_line in line.tabbed:
		match tabbed_line.type:
			"option": options.append(tabbed_line)
			_: lines.append(tabbed_line)
	
	line.tabbed = lines
	
	if options:
		line.options = options

static func _extract_properties(line: Dictionary) -> bool:
	if _extract(line, "((", "))", "prop"):
		var properties := {}
		for prop in line.prop.split(" "):
			if ":" in prop:
				var p = prop.split(":", true, 1)
				properties[p[0]] = p[1]
		line.prop = properties
		return true
	return false

static func _extract_action(line: Dictionary) -> bool:
	return _extract(line, "[[", "]]", "action")

static func _extract_conditional(line: Dictionary) -> bool:
	return _extract(line, "{{", "}}", "cond")

static func _extract(line: Dictionary, head: String, tail: String, key: String) -> bool:
	var p := UString.extract(line.text, head, tail)
	line.text = p[0]
	if p[1] != "":
		line[key] = p[1]
		return true
	return false

static func _erase(d: Dictionary, keys: Array):
	for k in keys:
		d.erase(k)

static func _trailing_tokens(s: String, splitters: Array) -> Array:
	var f := UString.split_on_next(s, splitters)
	var token: String = f[0]
	var left_side: String = f[1]
	var left_over: String = f[2]
	if token == "":
		return [s, []]
	var tokens := [[token, left_over]]
	while true:
		f = UString.split_on_next(left_over, splitters)
		if f[0] == "":
			break
		tokens[-1][1] = f[1]
		left_over = f[2]
		tokens.append([f[0], left_over])
	return [left_side, tokens]

static func _count_leading_tabs(s: String) -> int:
	var out := 0
	for c in s:
		match c:
			"\t": out += 4
			" ": out += 1
			_: break
	out /= 4
	return out
