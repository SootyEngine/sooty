@tool
extends Node

const CHECK_FILES_EVERY := 1 # seconds before checking if any script has changed.

signal reloaded_dialogue(dialogue: Dialogue)
signal reloaded()

var cache := {}

func _ready() -> void:
	await get_tree().process_frame
	Mods.pre_loaded.connect(_clear_mods)
	Mods.load_all.connect(_load_mods)
	
	if not Engine.is_editor_hint():
		# timer chat checks if any files were modified.
		var timer := Timer.new()
		add_child(timer)
		timer.timeout.connect(_timer)
		timer.start(CHECK_FILES_EVERY)

func _clear_mods():
	cache.clear()

func _load_mods(mods: Array):
	var memory_before = OS.get_static_memory_usage()
	var soot_paths := {}
	var lang_paths := {}
	
	# collect all files by name, so they can be merged if from mods.
	for mod in mods:
		mod.meta["dialogues"] = []
		for soot_path in UFile.get_files(mod.dir.plus_file("dialogue"), Soot.EXT_DIALOGUE):
			mod.meta.dialogues.append(soot_path)
			var id := UFile.get_file_name(soot_path)
			UDict.append(soot_paths, id, soot_path)
		
		mod.meta["langs"] = []
		for lang_path in UFile.get_files(mod.dir.plus_file("lang"), "-en" + Soot.EXT_LANG):
			mod.meta.langs.append(lang_path)
			var id := UFile.get_file_name(lang_path).rsplit("-", true, 1)[0]
			UDict.append(lang_paths, id, lang_path)
	
	for id in soot_paths:
		cache[id] = Dialogue.new(id, soot_paths[id], lang_paths.get(id, []))
	
	var memory_used = OS.get_static_memory_usage() - memory_before
	prints("Dialogues:", String.humanize_size(memory_used))

func has_dialogue(id: String) -> bool:
	return id in cache

func has_dialogue_flow(id: String) -> bool:
	if not Soot.is_path(id):
		return false
	var p := Soot.split_path(id)
	if not has_dialogue(p[0]):
		return false
	var d := get_dialogue(p[0])
	if not d.has_flow(p[1]):
		return false
	return true

func get_dialogue_ids() -> Dictionary:
	var out := {}
	for id in cache:
		out[id] = cache[id].flows.keys()
	return out

func _timer():
	var modified := false
	for d in cache.values():
		if d.was_modified():
			print("Reloading dialogue: %s" % d.id)
			d.reload()
			reloaded_dialogue.emit(d)
			modified = true
	if modified:
		reloaded.emit()

func get_dialogue(id: String) -> Dialogue:
	return cache.get(id, null)
