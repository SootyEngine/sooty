extends Node

const DIR := "user://saves"
const PREVIEW_SIZE_DIV_AMOUNT := 3.0
const SAVE_GROUP := "has_save_state"

func _ready() -> void:
	var d := Directory.new()
	if not d.dir_exists(DIR):
		d.make_dir(DIR)

func get_slot_names() -> PackedStringArray:
	var out := PackedStringArray()
	var d := Directory.new()
	d.open(DIR)
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if d.current_is_dir() and fname.begins_with("slot_"):
			out.append(fname.trim_prefix("slot_"))
		fname = d.get_next()
	d.list_dir_end()
	return out

func save_to_slot(slot: String):
	var slot_path := DIR.plus_file("slot_" + slot)
	
	var d := Directory.new()
	if not d.dir_exists(slot_path):
		d.make_dir(slot_path)
	
	# preview image
	var vp := get_viewport()
	var img := vp.get_texture().get_image()
	var siz := img.get_size() / PREVIEW_SIZE_DIV_AMOUNT
	img.resize(ceil(siz.x), ceil(siz.y), Image.INTERPOLATE_LANCZOS)
	img.save_png(slot_path.plus_file("preview.png"))
	
	# state data
	var state := {}
	for node in get_tree().get_nodes_in_group("has_save_state"):
		state[node.name] = node.get_save_state()
	UFile.save_to_resource(slot_path.plus_file("state.res"), state)
	
	# save slot info
	var slot_info := {
		time=Time.get_datetime_dict_from_system()
	}
	UFile.save_json(slot_path.plus_file("slot.json"), slot_info)
	
