@tool
extends Node

const CHECK_FILES_EVERY := 1 # seconds before checking if any script has changed.

signal reloaded_dialogue(dialogue: Dialogue)
signal reloaded()

var cache := {}
var ignored := []

func _ready() -> void:
	await get_tree().process_frame
	Mods.load_all.connect(_load_mods)
	
#	if not Engine.is_editor_hint():
	# timer chat checks if any files were modified.
	var timer := Timer.new()
	add_child(timer)
	timer.timeout.connect(_timer)
	timer.start(CHECK_FILES_EVERY)

func _load_mods(mods: Array):
	cache.clear()
	ignored.clear()
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
		var d := Dialogue.new(id, soot_paths[id], lang_paths.get(id, []))
		if d.has_IGNORE:
			ignored.append(d)
		else:
			cache[id] = d
	
	var memory_used = OS.get_static_memory_usage() - memory_before
	prints("Dialogues:", String.humanize_size(memory_used))

func has(id: String) -> bool:
	return id in cache

func find(id: String) -> Dialogue:
	if id in cache:
		return cache[id]
	UString.push_error_similar("No dialogue %s." % id, id, cache.keys())
	return null

func has_flow(id: String) -> bool:
	if not Soot.is_path(id):
		return false
	var p := Soot.split_path(id)
	if not has(p[0]):
		return false
	var d: Dialogue = cache[p[0]]
	if not d.has_flow(p[1]):
		return false
	return true

func get_dialogue(id: String) -> Dialogue:
	return cache.get(id, null)

func get_flow_ids() -> Dictionary:
	var out := {}
	for id in cache:
		out[id] = cache[id].flows.keys()
	return out

func _timer():
	var modified := false
	for d in cache.values() + ignored:
		if d.was_modified():
			print("Reloading dialogue: %s" % d.id)
			d.reload()
			if d.has_IGNORE:
				# remove from main cache
				if d in cache.values():
					cache.erase(d.id)
				# add to ignored list
				if not d in ignored:
					ignored.append(d)
			else:
				# add to main cache
				if not d in cache.values():
					cache[d.id] = d
				# remove from ignored list
				if d in ignored:
					ignored.erase(d)
				# alert others
			reloaded_dialogue.emit(d)
			modified = true
	if modified:
		reloaded.emit()
