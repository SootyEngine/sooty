extends Node

const DIR := "user://saves"
const PREVIEW_SIZE_DIV_AMOUNT := 3.0 # How much to shrink preview image.

const GROUP_SAVE_STATE := "has_save_state"
const GROUP_SAVE_INFO := "has_save_info"

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

func get_slot_directory(slot: String) -> String:
	return DIR.plus_file("slot_" + slot)

func get_slot_info(slot: String) -> Dictionary:
	return UFile.load_json(get_slot_directory(slot).plus_file("info.json"), {})

func save_to_slot(slot: String):
	var slot_path := get_slot_directory(slot)
	
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
	for node in get_tree().get_nodes_in_group(GROUP_SAVE_STATE):
		state[node.name] = node.get_save_state()
	UFile.save_to_resource(slot_path.plus_file("state.res"), state)
	
	# save slot info
	var slot_info := { time=Time.get_datetime_dict_from_system() }
	for node in get_tree().get_nodes_in_group(GROUP_SAVE_INFO):
		UDict.patch(slot_info, node.get_save_info())
	UFile.save_json(slot_path.plus_file("info.json"), slot_info)
	
