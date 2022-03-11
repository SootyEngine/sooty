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
	
	var data := DialogueParser.parse(file)
	UDict.merge(flows, data.flows)
	UDict.merge(lines, data.lines)
#	UDict.log(out_flows)
#	UDict.log(out_lines)
	
#	UFile.save_json("res://dialogue_debug/%s.flows.json" % [id], flows, true)
#	UFile.save_json("res://dialogue_debug/%s.lines.json" % [id], lines, true)

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
	return to_flow_id(flow) in flows

func get_flow_lines(flow: String) -> Array[String]:
	var out := []
	# lines in flows begining with
	if flow.begins_with("*"):
		flow = flow.trim_prefix("*")
		for f in flows.keys():
			if f.ends_with(flow):
				out.append_array(get_flow(f).then)
	# lines in flows ending with
	elif flow.ends_with("*"):
		flow = flow.trim_suffix("*")
		for f in flows.keys():
			if f.begins_with(flow):
				out.append_array(get_flow(f).then)
	# lines in flow alone
	else:
		var f := get_flow(flow)
		out.append_array(f.then)
	return out

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

func get_line(line: String) -> Dictionary:
	if line in lines:
		return lines[line]
	push_error("No line '%s' in dialogue '%s'." % [line, id])
	return {}

func get_lines(lines: Array[String]) -> Array[Dictionary]:
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
