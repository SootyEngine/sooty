@tool
extends Node

const CHECK_FILES_EVERY := 1

signal reloaded(dialogue: Dialogue)

var cache := {}

func get_dialogue_ids() -> Dictionary:
	var out := {}
	for id in cache:
		out[id] = cache[id].flows.keys()
	return out

func _ready() -> void:
	if not Engine.is_editor_hint():
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

func get_dialogue(id: String) -> Dialogue:
	if not id in cache:
		var d := Dialogue.new(id)
		if d.has_errors():
			push_error("Bad dialogue: %s." % id)
			return null
		else:
			add_dialogue(id, d)
			return d
	else:
		return cache[id]

func add_dialogue(id: String, d: Dialogue):
	d.id = id
	cache[id] = d
