extends Resource
class_name Dialogue

@export var id := ""
@export var flows := {}
@export var lines := {}
@export var errors := []
@export var path := ""
@export var last_modified := 0

func _init(text: String, is_id: bool = true):
	if is_id:
		path = "res://dialogue/%s.soot" % text.replace(".", "/")
		_reload()
	else:
		_reload_from_text(text)

func _reload():
	var text := UFile.load_text(path)
	_reload_from_text(text)
	last_modified = UFile.get_modified_time(path)

func _reload_from_text(text: String):
	flows.clear()
	lines.clear()
	
	var text_lines := text.split("\n")
	var blocks := []
	var stack := []
	var i := 0
	for i in len(text_lines):
		if text_lines[i].strip_edges() == "":
			continue
		
		if text_lines[i].strip_edges(true, false).begins_with("//"):
			continue
		
		var deep := _count_leading_tabs(text_lines[i])
		var line := { line=i, text=text_lines[i].strip_edges(), lines=[] }
		
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
	return path != "" and UFile.get_modified_time(path) != last_modified

func has_errors() -> bool:
	return len(errors) != 0

func has_flows() -> bool:
	return len(flows) != 0

func get_flow(id: String) -> Dictionary:
	return flows.get(to_flow_id(id), {})

func get_line(id: int) -> Dictionary:
	return lines.get(id, {})

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
	line.erase("line")
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
	if text.begins_with(">"): return _parse_option(data)
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
	data.text = data.text.substr(len(">"))
	
	_extract_flow_option(data)
	
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
		data.goto = p[1].strip_edges()
	
	if "::" in data.text:
		var p = data.text.split("::", true, 1)
		data.text = p[0].strip_edges()
		data.call = p[1].strip_edges()

func _extract_comment(data: Dictionary):
	var text: String = data.text
	if "//" in text:
		var p := text.rsplit("//", true, 1)
		data.text = p[0].strip_edges(false, true)
		data.comment = p[1].strip_edges()

func _extract_properties(data: Dictionary):
	var text: String = data.text
	if "((" in text:
		var p := text.split("((", true, 1)
		data.text = p[0].strip_edges()
		var properties := {}
		
		if "))" in p[1]:
			p = p[1].split("))", true, 1)
			data.text += p[1].strip_edges()
			
			for prop in p[0].split(" "):
				if ":" in prop:
					p = prop.split(":", true, 1)
					properties[p[0]] = p[1]
		
		data.properties = properties

func _extract_conditional(data: Dictionary):
	var text: String = data.text
	if "{{" in text:
		var p := text.split("{{", true, 1)
		data.text = p[0].strip_edges()
		
		if "}}" in p[1]:
			p = p[1].split("}}", true, 1)
			data.text += p[1].strip_edges()
			
			data.condition = p[0]

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
