extends Node

const CHECK_FILES_EVERY := 1

signal reloaded(dialogue: Dialogue)

var load_all_on_startup := true
var cache := {}

func get_dialogue_ids() -> Dictionary:
	var out := {}
	for id in cache:
		out[id] = cache[id].flows.keys()
	return out

func _ready() -> void:
	if load_all_on_startup:
		for file in UFile.get_files("res://dialogue", ".soot"):
			var d := Dialogue.new(file)
			cache[d.id] = d
	
	var timer := Timer.new()
	add_child(timer)
	timer.timeout.connect(_timer)
	timer.start(CHECK_FILES_EVERY)

func _timer():
	for d in cache.values():
		if d.was_file_modified():
			print("reload: %s" % d.path)
			d._reload()
			reloaded.emit(d)

const DIR_RES := "res://dialogue"
func get_dialogue(id: String) -> Dialogue:
	if not id in cache:
		var d := Dialogue.new(DIR_RES.plus_file("%s.soot"))
		if d.has_errors():
			push_error("Bad dialogue: %s." % id)
			return null
		else:
			add_dialogue(d)
			return d
	else:
		return cache[id]

func get_flow(flow: String) -> Dictionary:
	var p := flow.split(".", true, 1)
	var d := get_dialogue(p[0])
	return d.get_flow(p[1])

func get_flow_lines(flow: String) -> Array[String]:
	var p := flow.split(".", true, 1)
	var d := get_dialogue(p[0])
	flow = p[1]
	var out := []
	# lines in flows begining with
	if flow.begins_with("*"):
		flow = flow.trim_prefix("*")
		for f in d.flows.keys():
			if f.ends_with(flow):
				out.append_array(d.get_flow(f).lines)
	# lines in flows ending with
	elif flow.ends_with("*"):
		flow = flow.trim_suffix("*")
		print("FLOWS ENDING IN ", flow)
		for f in d.flows.keys():
			if f.begins_with(flow):
				print("\t", f)
				out.append_array(d.get_flow(f).lines)
	# lines in flow alone
	else:
		var f := d.get_flow(flow)
		print(f)
		out.append_array(f.lines)
	
	return out

func add_dialogue(d: Dialogue):
	cache[d.id] = d
