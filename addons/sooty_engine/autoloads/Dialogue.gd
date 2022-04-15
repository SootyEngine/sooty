@tool
extends Flow

const CHECK_FILES_EVERY := 1 # seconds before checking if any script has changed.

signal reloaded()
signal caption(text: String, line: Dictionary)

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("@:Dialogue")
	add_to_group("@.chose")
	add_to_group("@.reset_choice")
	add_to_group("@.reset_list")
	selected.connect(_choose)

# check if a choise was made
func chose(id: String) -> bool:
	return states.get(id, 0) > 0

# clear choice count
func reset_choice(id: String):
	states.erase(id)

# increase the tick count for this choice
func _choose(id: String):
	UDict.tick(states, id)

func _ready() -> void:
	reloaded.connect(_reloaded)
	
	await get_tree().process_frame
	Mods.load_all.connect(_load_mods)

func _files_modified(file_scanner: FileModifiedScanner):
	file_scanner.update_times()
	Mods._load_mods()

func _on_step(step: Dictionary):
	match step.type:
		"text": caption.emit(step.text, step)

func _reloaded():
#	clear_waiting_list()
	_stack = _last_tick_stack.duplicate(true)

func _load_mods(mods: Array):
	_flows.clear()
	_lines.clear()
	
	var memory_before = OS.get_static_memory_usage()
	var soot_blocks := {}
	var lang_paths := {}
	var all_files := []
	
	# collect all files by name, so they can be merged if from mods.
	for mod in mods:
		mod.meta["dialogue"] = []
		var soot_files := UFile.get_files(mod.dir.plus_file("dialogue"), "." + Soot.EXT_DIALOGUE)
		all_files.append_array(soot_files)
		
		for soot_path in soot_files:
			mod.meta.dialogue.append(soot_path)
			DialogueParser.new()._parse(soot_path, _flows, _lines)
		
		mod.meta["lang"] = []
		var lang_files := UFile.get_files(mod.dir.plus_file("lang"), "-en." + Soot.EXT_LANG)
		all_files += Array(lang_files)
		for lang_path in lang_files:
			mod.meta.lang.append(lang_path)
			var id := UFile.get_file_name(lang_path).rsplit("-", true, 1)[0]
			UDict.append(lang_paths, id, lang_path)
	
	# timer checks if any files were modified.
	UNode.remove_children(self)
	var file_scanner := FileModifiedScanner.new()
	file_scanner.set_name("FileScanner")
	add_child(file_scanner)
	file_scanner.modified.connect(_files_modified.bind(file_scanner))
	file_scanner.set_files(all_files)
	
	# save states for debuging
	if UFile.exists("res://debug_output/dialogue"):
		UFile.save_text("res://debug_output/dialogue/_all_flows.soda", DataParser.dict_to_str(_flows))
		UFile.save_text("res://debug_output/dialogue/_all_lines.soda", DataParser.dict_to_str(_lines))
	
	# probably not accurate
	var memory_used = OS.get_static_memory_usage() - memory_before
	prints("Dialogues:", String.humanize_size(memory_used))

#func find(id: String) -> Dialogue:
#	if id in cache:
#		return cache[id]
#	else:
#		UString.push_error_similar("No dialogue %s." % id, id, cache.keys())
#		return null
