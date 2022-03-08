extends Node

const DIR := "user://mods"

var loaded := []

func _ready() -> void:
	var d := Directory.new()
	if not d.dir_exists(DIR):
		d.make_dir(DIR)
	
	for mod in get_mod_names():
		load_mod(mod)

func get_mod_names() -> PackedStringArray:
	var out := PackedStringArray()
	var d := Directory.new()
	d.open(DIR)
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if d.current_is_dir():
			out.append(fname)
		fname = d.get_next()
	d.list_dir_end()
	return out

func load_mod(mod: String):
	var mod_path := DIR.plus_file(mod)
	print("Loading Mod: %s" % mod)
	
	# load soot
	for file in UFile.get_files(mod_path.plus_file("dialogue"), "soot"):
		var d := Dialogue.new(file)
		var flows := len(d.flows)
		print("\t+ %s (%s - %sx flows)" % [file.trim_prefix(mod_path), d.id, flows])
		DialogueServer.add_dialogue(d)
	
	# load state
	var state_path := mod_path.plus_file("state.json")
	if UFile.file_exists(state_path):
		var state: Dictionary = UFile.load_json(state_path)
		var lines_changed := UObject.patch(State, state)
		print("\t+ %s (%s properties modified)" % [state_path.trim_prefix(mod_path), lines_changed])
	
	var state_script_path := mod_path.plus_file("state.gd")
	if UFile.file_exists(state_script_path):
#		var source_code := UFile.load_text(state_script_path)
		print("\t+ %s" % [state_script_path.trim_prefix(mod_path)])
		
		State._mods.append(load(state_script_path).new())
	
	for m in State._mods:
		if m.has_method("_post_init"):
			m._post_init()
	
	op.call_deferred()
	
func op():
	#print(JSON.new().stringify(State._get_state(), "\t", false))
	print(DialogueServer.get_dialogue_ids())
#func _merge_script_parts(a: Array) -> String:
#	var lines = ["extends GameStateBase"]
#	var funcs = {}
#	for sp in a:
#		lines.append_array(sp.lines)
#
#		for f in sp.funcs:
#			var fdata = sp.funcs[f]
#			if not f in funcs:
#				funcs[f] = [fdata.head, "\tsuper.%s()" % fdata.id]
#			funcs[f].append_array(fdata.lines)
#
#	for f in funcs:
#		lines.append_array(funcs[f])
#
#	return "\n".join(lines)
#
#func _get_script_parts(s: String) -> Dictionary:
#	var out := {
#		lines = [],
#		funcs = {}
#	}
#	var last_func := {}
#	var in_func := false
#	for line in s.split("\n", false):
#		if line.begins_with("@tool") or line.begins_with("extends "):
#			continue
#
#		if line.begins_with("func "):
#			in_func = true
#			var id := line.split("func ", true, 1)[1].split("(", true, 1)[0]
#			last_func = {
#				id = id,
#				head = line,
#				lines = []
#			}
#			out.funcs[id] = last_func
#			continue
#
#		elif len(line.strip_edges(true, false)) == len(line):
#			in_func = false
#
#		if in_func:
#			if line.begins_with("\tsuper.%s()" % last_func.id):
#				continue
#			else:
#				last_func.lines.append(line)
#		else:
#			out.lines.append(line)
#
#	return out
