@tool
extends Flow

const CHECK_FILES_EVERY := 2.0 # seconds before checking if any script has changed.

signal reloaded()
signal caption(text: String, line: Dictionary)

func _ready() -> void:
	super._ready()
	_sooty.actions.connect_as_node(self, "Dialogue")
	_sooty.actions.connect_methods([chose, reset_choice, reset_list])
	_sooty.mods.load_all.connect(_load_mods)
	selected.connect(_choose)
	reloaded.connect(_reloaded)
	
# check if a choise was made
func chose(id: String) -> bool:
	return states.get(id, 0) > 0

# clear choice count
func reset_choice(id: String):
	states.erase(id)

# increase the tick count for this choice
func _choose(id: String):
	UDict.tick(states, id)

func _files_modified(file_scanner: FileModifiedScanner):
	file_scanner.update_times()
	_sooty.mods.load_mods()

func _on_step(step: Dictionary):
	match step.type:
		"text": caption.emit(step.text, step)

func _reloaded():
#	clear_waiting_list()
	_stack = _last_tick_stack.duplicate(true)

func _load_mods(mods: Array):
	flows.clear()
	lines.clear()
	
	var memory_before = OS.get_static_memory_usage()
	var soot_blocks := {}
	var lang_paths := {}
	var all_files := []
	var total_bytes := 0
	
	# collect all files by name, so they can be merged if from mods.
	for mod in mods:
		mod.meta["dialogue"] = []
		var soot_files := UFile.get_files(mod.dir.plus_file("dialogue"), "." + Soot.EXT_DIALOGUE)
		all_files.append_array(soot_files)
		
		for soot_path in soot_files:
			total_bytes += UFile.get_file_size(soot_path)
			mod.meta.dialogue.append(soot_path)
			DialogueParser.new()._parse(soot_path, flows, lines)
		
		mod.meta["lang"] = []
		var lang_files := UFile.get_files(mod.dir.plus_file("lang"), "-en." + Soot.EXT_LANG)
		all_files += Array(lang_files)
		for lang_path in lang_files:
			mod.meta.lang.append(lang_path)
			var id := UFile.get_file_name(lang_path).rsplit("-", true, 1)[0]
			UDict.append(lang_paths, id, lang_path)
	
	# timer checks if any files were modified.
	UGroup.remove("_dialogue_timer_")
	var file_scanner := FileModifiedScanner.new()
	Global.add_child(file_scanner)
	file_scanner.add_to_group("_dialogue_timer_")
	file_scanner.set_name("FileScanner")
	file_scanner.modified.connect(_files_modified.bind(file_scanner))
	file_scanner.set_files(all_files)
	
	# save states for debuging
	if UFile.exists("res://debug_output/dialogue"):
		UFile.save_text("res://debug_output/dialogue/_all_flows.soda", DataParser.dict_to_str(flows))
		UFile.save_text("res://debug_output/dialogue/_all_lines.soda", DataParser.dict_to_str(lines))
	
	# probably not accurate
	var memory_used = OS.get_static_memory_usage() - memory_before
	prints("Dialogues: %s >>> %s." % [String.humanize_size(total_bytes), String.humanize_size(memory_used)])

