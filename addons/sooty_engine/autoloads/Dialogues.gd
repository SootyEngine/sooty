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
		var memory_before = OS.get_static_memory_usage()
		for file in UFile.get_files("res://dialogue", ".soot"):
			add_dialogue(Dialogue.new(file))
		var memory_used = OS.get_static_memory_usage() - memory_before
		prints("Dialogues:", String.humanize_size(memory_used))
	
	# timer chat checks if any files were modified.
	var timer := Timer.new()
	add_child(timer)
	timer.timeout.connect(_timer)
	timer.start(CHECK_FILES_EVERY)

func add_dialogue(d: Dialogue):
	cache[d.id] = d

func _timer():
	for d in cache.values():
		if d.was_file_modified():
			print("Relading dialogue: %s" % d.id)
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

func get_flow_lines(flow: String) -> Array[String]:
	var p := flow.split(".", true, 1)
	return get_dialogue(p[0]).get_flow_lines(p[1])
