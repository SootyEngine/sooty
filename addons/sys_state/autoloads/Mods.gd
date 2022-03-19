extends Node

const DIR := "user://mods"

signal enabled(mod: String)
signal disabled(mod: String)

var auto_load_mods := false
var loaded := []

func _init() -> void:
	add_to_group(SaveManager.GROUP_SAVE_STATE)

func get_save_state():
	return { loaded=loaded }

func load_save_state(state: Variant):
	loaded = state.get("loaded", loaded)

func _ready() -> void:
	var d := Directory.new()
	if not d.dir_exists(DIR):
		d.make_dir(DIR)
	
	if auto_load_mods:
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
		Dialogues.add_dialogue(d)
	
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
	
