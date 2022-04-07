extends Resource
class_name Dialogue

@export var id := ""
@export var flows := {}
@export var lines := {}
@export var errors := []
@export var files := []
@export var langs := []
@export var modified_at := {} # values are modified times
@export var has_IGNORE := false

func _init(id: String, files: Array, langs := []):
	self.id = id
	self.files = files
	self.langs = langs
	reload()

func reload():
	# update all timers
	for file in files + langs:
		modified_at[file] = UFile.get_modified_time(file)
	
	# parse
	var data := DialogueParser.new(id, files, langs).parse()
	if data:
		has_IGNORE = false
		flows = data.flows
		lines = data.lines
		if UFile.dir_exists("res://dialogue_debug"):
			UFile.save_json("res://dialogue_debug/%s.flows.json" % [id], flows, true)
			UFile.save_json("res://dialogue_debug/%s.lines.json" % [id], lines, true)
	else:
		has_IGNORE = true

func generate_language_file(lang: String):
	if not has_IGNORE:
		DialogueParser.new(id, files).parse(lang)

func was_modified() -> bool:
	for file in modified_at:
		if modified_at[file] != UFile.get_modified_time(file):
			return true
	return false

func has_errors() -> bool:
	return len(errors) != 0

func has_flows() -> bool:
	return len(flows) != 0

func has_flow(flow: String) -> bool:
	return flow in flows

func find(flow: String) -> Dictionary:
	if flow in flows:
		return flows[flow]
	else:
		UString.push_error_similar("No '%s' in '%s'." % [flow, id], flow, flows.keys())
		return {}

func get_flow_lines(flow: String) -> Array[String]:
	var out := []
	# lines in flows begining with
	if flow.begins_with("*"):
		var search = flow.trim_prefix("*")
		for f in flows.keys():
			if f.ends_with(search):
				out.append_array(get_flow(f).then)
	# lines in flows ending with
	elif flow.ends_with("*"):
		var search = flow.trim_suffix("*")
		for f in flows.keys():
			if f.begins_with(search):
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
	
	var err := "No flow '%s' in dialogue '%s'." % [flow, id]
	UString.push_error_similar(err, flow, flows.keys())
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
	return s
#	var out := ""
#	for c in s.capitalize().to_lower():
#		if c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
#			out += c
#		elif out != "" and out[-1] != "_":
#			out += "_"
#	return out
