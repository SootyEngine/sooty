extends Node

const CHECK_FILES_EVERY := 1

signal reloaded(dialogue: Dialogue)

var cache := {}

func _init() -> void:
	Mods.pre_loaded.connect(_clear_mods)
	Mods.load_all.connect(_load_mods)

func _clear_mods():
	cache.clear()

func _load_mods(mods: Array):
	var memory_before = OS.get_static_memory_usage()
	for mod in mods:
		var head = mod.dir.plus_file("dialogue")
		mod.meta["dialogues"] = []
		for soot_path in UFile.get_files(head, ".soot"):
			mod.meta.dialogues.append(soot_path)
			var d := Dialogue.new(soot_path)
			cache[d.id] = d
	var memory_used = OS.get_static_memory_usage() - memory_before
	prints("Dialogues:", String.humanize_size(memory_used))

func _ready() -> void:
	# timer chat checks if any files were modified.
	var timer := Timer.new()
	add_child(timer)
	timer.timeout.connect(_timer)
	timer.start(CHECK_FILES_EVERY)

func has(id: String) -> bool:
	return id in cache
	
func get_dialogue_ids() -> Dictionary:
	var out := {}
	for id in cache:
		out[id] = cache[id].flows.keys()
	return out

func _timer():
	return
	for d in cache.values():
		if d.was_file_modified():
			print("Relading dialogue: %s" % d.id)
			d._reload()
			reloaded.emit(d)

#const DIR_RES := "res://dialogue"
func get_dialogue(id: String) -> Dialogue:
	return cache.get(id, null)
#	if not id in cache:
#		var d := Dialogue.new(DIR_RES.plus_file("%s.soot"))
#		if d.has_errors():
#			push_error("Bad dialogue: %s." % id)
#			return null
#		else:
#			add_dialogue(d)
#			return d
#	else:
#		return cache[id]

#func get_flow_lines(flow: String) -> Array[String]:
#	var p := flow.split(".", true, 1)
#	return get_dialogue(p[0]).get_flow_lines(p[1])
