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
	for file in UFile.get_files(mod_path, "soot"):
		var d := Dialogue.new(UFile.load_text(file), false)
		var id := file.get_file().get_basename()
		var flows := len(d.flows)
		print("\t+ %s (%s - %sx flows)" % [file.trim_prefix(mod_path), id, flows])
		DialogueServer.add_dialogue(id, d)
