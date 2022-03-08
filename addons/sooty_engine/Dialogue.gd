extends Resource
class_name Dialogue

@export var id := ""
@export var flows := {}
@export var lines := {}
@export var errors := []
@export var files := {}
@export var last_modified := 0

func _init(file: String):
	id = file.split("dialogue/", true, 1)[1].rsplit(".")[0]
	_parse_file(file)

func patch(file: String):
	_parse_file(file)

func _reload():
	flows.clear()
	lines.clear()
	for file in files:
		_parse_file(file)

func _parse_file(file: String):
	files[file] = UFile.get_modified_time(file)
	var text_lines := UFile.load_text(file).split("\n")
	var blocks := []
	var stack := []
	var i := 0
	var file_index := files.keys().find(file)
	
	for i in len(text_lines):
		if text_lines[i].strip_edges() == "":
			continue
		
		if text_lines[i].strip_edges(true, false).begins_with("//"):
			continue
		
		var deep := _count_leading_tabs(text_lines[i])
		var line := { line=i, file=file_index, text=text_lines[i].strip_edges(), lines=[] }
		
		if deep+1 > len(stack):
			stack.resize(deep+1)
		
		_extract_comment(line)
		_extract_conditional(line)
		_extract_properties(line)
		stack[deep] = line
		
		if deep == 0:
			blocks.append(line)
		else:
			stack[deep-1].lines.append(line)
	
	for i in len(blocks):
		blocks[i] = _parse_block(blocks[i])
	
#	output(flows)
#	output(lines)

func was_file_modified() -> bool:
	for file in files:
		if files[file] != UFile.get_modified_time(file):
			return true
	return false

func has_errors() -> bool:
	return len(errors) != 0

func has_flows() -> bool:
	return len(flows) != 0

func has_flow(flow: String) -> bool:
	flow = to_flow_id(flow)
	return flow in flows

func get_flow(flow: String) -> Dictionary:
	flow = to_flow_id(flow)
	if flow in flows:
		return flows[flow]
	
	var most_similar := UString.find_most_similar(flow, flows.keys())
	if len(most_similar):
		push_error("No flow '%s' in dialogue '%s'. Did you mean '%s'?" % [flow, id, "', '".join(most_similar)])
	else:
		push_error("No flow '%s' in dialogue '%s'." % [flow, id])
	
	return {}

func get_line(line: int) -> Dictionary:
	if line in lines:
		return lines[line]
	push_error("No line '%s' in dialogue '%s'." % [line, id])
	return {}

func get_lines(lines: Array[int]) -> Array[Dictionary]:
	var out := []
	for i in len(lines):
		out.append(get_line(lines[i]))
	return out

func to_flow_id(s: String) -> String:
	var out := ""
	for c in s.capitalize().to_lower():
		if c in "abcdefghijklmnopqrstuvwxyz0123456789":
			out += c
		elif out != "" and out[-1] != "_":
			out += "_"
	return out

func _line_to_index(line: Dictionary) -> int:
	var index: int = line.line
	lines[index] = line
	return index

func _parse_block(block: Dictionary) -> Dictionary:
	var text: String = block.text
	if text.begins_with("==="): return _parse_flow(block)
	return block

func _parse_flow(flow: Dictionary) -> Dictionary:
	flow.text = flow.text.split(" ", true, 1)[-1]
	_parse_lines(flow)
	flows[to_flow_id(flow.text)] = flow
	return flow

func _parse_lines(line: Dictionary, key: String = "lines"):
	var list = line.lines
	line.erase("lines")
	
	var new_list := []
	for i in len(list):
		var l = _parse_line(list[i])
		if "is_prop_line" in l:
			if not "properties" in line:
				line.properties = {}
			_merge(line.properties, l.properties)
		else:
			new_list.append(_line_to_index(l))
	
	line[key] = new_list

func _parse_line(data: Dictionary) -> Dictionary:
	var text = data.text
	if text.begins_with("<"): return _parse_option(data)
	if text.begins_with("@"): return _parse_action(data)
	if text.begins_with(">>"): return _parse_flow_goto(data)
	if text.begins_with("::"): return _parse_flow_call(data)
	if text.begins_with("|"): return _parse_line_property(data)
	return _parse_dialogue(data)

func _parse_line_property(data: Dictionary) -> Dictionary:
	var properties := {}
	for prop in data.text.substr(2).split(" "):
		var p = prop.split(":", true, 1)
		properties[p[0]] = p[1]
	
	data.properties = properties
	data.is_prop_line = true
	
	return data
	
func _parse_option(data: Dictionary) -> Dictionary:
	var text: String = data.text
	var a := text.find("<")
	var b := text.find(">", a)
	
	data.text = text.substr(b+1).strip_edges()
	data.flag = text.substr(a+1, b-a-1).strip_edges()
	
	_extract_flow_option(data)
	_extract_action(data)
	
	if "goto" in data:
		data.then_goto = data.goto
		data.erase("goto")
	
	if data.lines:
		_parse_lines(data)
	
	return data

func _parse_action(data: Dictionary) -> Dictionary:
	var text: String = data.text.substr(len("@"))
	data.action = text
	data.erase("text")
	data.erase("lines")
	return data

func _parse_dialogue(data: Dictionary) -> Dictionary:
	var text: String = data.text
	
	if ":" in text:
		var p := text.split(":", true, 1)
		data.from = p[0].strip_edges()
		data.text = p[1].strip_edges()
	
	if data.lines:
		# convert to line numbers
		_parse_lines(data, "options")
	
	data.erase("lines")
	return data

func _parse_flow_goto(data: Dictionary) -> Dictionary:
	_extract_flow_option(data)
	data.erase("text")
	data.erase("lines")
	return data

func _parse_flow_call(data: Dictionary) -> Dictionary:
	_extract_flow_option(data)
	data.erase("text")
	data.erase("lines")
	return data

func _extract_flow_option(data: Dictionary):
	if ">>" in data.text:
		var p = data.text.rsplit(">>", true, 1)
		data.text = p[0].strip_edges()
		data.flow = "goto"
		data.goto = p[1].strip_edges()
		if not "." in data.goto:
			data.goto = "%s.%s" % [id, data.goto]
	
	if "::" in data.text:
		var p = data.text.split("::", true, 1)
		data.text = p[0].strip_edges()
		data.flow = "call"
		data.call = p[1].strip_edges()
		if not "." in data.call:
			data.call = "%s.%s" % [id, data.call]

func _extract_action(data: Dictionary):
	var p := _trim_between(data.text, "[[", "]]")
	data.text = p[0]
	if p[1] != "":
		data.action = p[1]

func _extract_comment(data: Dictionary):
	var text: String = data.text
	if "//" in text:
		var p := text.rsplit("//", true, 1)
		data.text = p[0].strip_edges(false, true)
		data.comment = p[1].strip_edges()

func _extract_properties(data: Dictionary):
	var p := _trim_between(data.text, "((", "))")
	data.text = p[0]
	if p[1] != "":
		data.condition = p[1]
#	var text: String = data.text
#	if "((" in text:
#		var p := text.split("((", true, 1)
#		data.text = p[0].strip_edges()
#		var properties := {}
#
#		if "))" in p[1]:
#			p = p[1].split("))", true, 1)
#			data.text += p[1].strip_edges()
#
#			for prop in p[0].split(" "):
#				if ":" in prop:
#					p = prop.split(":", true, 1)
#					properties[p[0]] = p[1]
#
#		data.properties = properties

func _extract_conditional(data: Dictionary):
	var p := _trim_between(data.text, "{{", "}}")
	data.text = p[0]
	if p[1] != "":
		data.condition = p[1]
#	if "{{" in text:
#		var a := text.split("{{", true, 1)
#
#		if "}}" in a[1]:
#			a = a[1].split("}}", true, 1)
#			data.text += a[1].strip_edges()
#			data.condition = a[0]
#
#		else:
#			data.text = a[0].strip_edges()

func _trim_between(t: String, head: String, tail: String) -> Array:
	var a := t.find(head)
	if a != -1:
		var b := t.find(tail, a+len(head))
		if b != -1:
			var outer := t.substr(0, a).strip_edges(false, true) + t.substr(b+len(tail)).strip_edges(true, false)
			var inner := t.substr(a+len(head), b)
			return [outer, inner]
		else:
			var outer := t.substr(0, a).strip_edges(false, true)
			var inner :=  t.substr(a+len(head))
			return [outer, inner]
	else:
		return [t, ""]

func _count_leading_tabs(s: String) -> int:
	var out := 0
	for c in s:
		match c:
			"\t": out += 4
			" ": out += 1
			_: break
	out /= 4
	return out

func _merge(target: Dictionary, patch: Dictionary) -> Dictionary:
	for k in patch:
		target[k] = patch[k]
	return target

func _remove_comments(lines: PackedStringArray) -> PackedStringArray:
	for i in len(lines):
		lines[i] = lines[i].rsplit("\\", true, 1)[0]
	return lines

func output(data):
	print(JSON.new().stringify(data, "\t", false))
