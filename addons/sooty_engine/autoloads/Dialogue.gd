@tool
extends SootStack

const CHECK_FILES_EVERY := 1 # seconds before checking if any script has changed.

signal reloaded()
signal caption(from: String, text: String)

var dialogues := {}
var lines := {} # all lines from all files

func _ready() -> void:
	reloaded.connect(_reloaded)
	
	await get_tree().process_frame
	Mods.load_all.connect(_load_mods)
	
	if not Engine.is_editor_hint():
	# timer chat checks if any files were modified.
		var timer := Timer.new()
		add_child(timer)
		timer.timeout.connect(_check_for_modified)
		timer.start(CHECK_FILES_EVERY)

func _process(_delta: float) -> void:
	_tick()

func _on_step(step: Dictionary):
	match step.type:
		"flag": caption.emit("", step.flag, step)
		"prop": caption.emit(step.name, step.value, step)
		"action": StringAction.do(step.action)

func _reloaded():
	clear_waiting_list()
	_stack = _last_tick_stack.duplicate(true)

func _load_mods(mods: Array):
	dialogues.clear()
	lines.clear()
	
	var memory_before = OS.get_static_memory_usage()
	var soot_blocks := {}
	var lang_paths := {}
	
	# collect all files by name, so they can be merged if from mods.
	for mod in mods:
		mod.meta["dialogues"] = []
		for soot_path in UFile.get_files(mod.dir.plus_file("dialogue"), Soot.EXT_DIALOGUE):
			mod.meta.dialogues.append(soot_path)
			DialogueParser.new()._parse(soot_path, dialogues, lines)
		
		mod.meta["langs"] = []
		for lang_path in UFile.get_files(mod.dir.plus_file("lang"), "-en" + Soot.EXT_LANG):
			mod.meta.langs.append(lang_path)
			var id := UFile.get_file_name(lang_path).rsplit("-", true, 1)[0]
			UDict.append(lang_paths, id, lang_path)
	
	UDict.log(dialogues)
	
	if UFile.exists("res://dialogue_debug"):
		UFile.save_text("res://dialogue_debug/_dialogues.soda", DataParser.dict_to_str(dialogues))
		UFile.save_text("res://dialogue_debug/_all_lines.soda", DataParser.dict_to_str(lines))
	
#	for id in soot_blocks:
#		var blocks: Array = soot_blocks[id]
#		dialogues[id] = {
#			flows=[],
#			lines=[],
#			metas=[]
#		}
#
#		for block in blocks:
#			for flow_data in block.flows:
#				var flow_id := Soot.join_path([id, flow_data.id])
#				UDict.append(block.meta, "flows", flow_id)
#				dialogues[id].flows.append(flow_id)
#				flows[flow_id] = flow_data
#
#			for line_data in block.lines:
#				var line_id := Soot.join_path([id, line_data.M.id])
#				UDict.append(block.meta, "lines", line_id)
#				dialogues[id].lines.append(line_id)
#				lines[line_id] = line_data
#
#			dialogues[id].metas.append(block.meta)
	
#	UDict.log(dialogues)
#	UDict.log(flows)
#	UDict.log(lines)
	
	var memory_used = OS.get_static_memory_usage() - memory_before
	prints("Dialogues:", String.humanize_size(memory_used))

#func find(id: String) -> Dialogue:
#	if id in cache:
#		return cache[id]
#	else:
#		UString.push_error_similar("No dialogue %s." % id, id, cache.keys())
#		return null

#func has_flow(id: String) -> bool:
#	if not Soot.is_path(id):
#		return false
#	var p := Soot.split_path(id)
#	if not has(p[0]):
#		return false
#	var d: Dialogue = cache[p[0]]
#	if not d.has_flow(p[1]):
#		return false
#	return true

func _has_step(id: String) -> bool:
	return id in lines

func _get_step(id: String) -> Dictionary:
	return lines[id]

func has_flow(id: String) -> bool:
	return id in lines

func get_line(id: String) -> Dictionary:
	return lines.get(id, {})

func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})

#func get_flow_ids() -> Dictionary:
#	var out := {}
#	for id in cache:
#		out[id] = cache[id].flows.keys()
#	return out

func line_has_options(line: Dictionary) -> bool:
	return "options" in line

func line_has_condition(line: Dictionary) -> bool:
	return "cond" in line

func line_passes_condition(line: Dictionary) -> bool:
	return StringAction._test(line.cond)

func line_get_options(line: Dictionary) -> Array:
	var out_lines := []
	if line_has_options(line):
		_get_options(line.options, out_lines, 0)
	return out_lines

func _get_options(ids: Array, output: Array, depth: int):
	if depth > 4:
		push_error("Possible loop!?")
		return

	for i in len(ids):
		var line: Dictionary = get_line(ids[i])
		var passed := not line_has_condition(line) or line_passes_condition(line)
		match line.get("flag", ""):
			"++":
				# recursively collect options from other flows
				if passed:
					var flow_id: String = line.text
					var flow_step_ids: Array = get_line(flow_id).then
					_get_options(flow_step_ids, output, depth+1)
			_:
				output.append({id=ids[i], line=line, passed=passed})
#		if "flow" in opdata:
#			if opdata.flow == "call":
#				var fid: String = opdata.call
#				var flines := Dialogues.get_flow_lines(fid)
#				_get_options(flines, output, only_passing, depth+1)
#		else:
#			if only_passing and "cond" in opdata and not StringAction.test(opdata.cond):
#				continue
#
#			out.append(DialogueLine.new(_dialogue_id, opdata))

func _check_for_modified():
	return
#	var modified := false
#	for d in cache.values() + ignored:
#		if d.was_modified():
#			print("Reloading dialogue: %s" % d.id)
#			d.reload()
#			if d.has_IGNORE:
#				# remove from main cache
#				if d in cache.values():
#					cache.erase(d.id)
#				# add to ignored list
#				if not d in ignored:
#					ignored.append(d)
#			else:
#				# add to main cache
#				if not d in cache.values():
#					cache[d.id] = d
#				# remove from ignored list
#				if d in ignored:
#					ignored.erase(d)
#				# alert others
#			reloaded_dialogue.emit(d)
#			modified = true
#	if modified:
#		reloaded.emit()
