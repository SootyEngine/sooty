extends Node

const DIR := "user://saves"
const PREVIEW_SIZE_DIV_AMOUNT := 3.0 # How much to shrink preview image.

signal pre_save()
signal pre_load()
signal saved()
signal loaded()
# internally collect all state data
signal _get_state(data: Dictionary)
signal _set_state(data: Dictionary)
# internall collect state info
signal _get_state_info(data: Dictionary)

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
		if d.current_is_dir():# and fname.begins_with("slot_"):
			out.append(fname)#.trim_prefix("slot_"))
		fname = d.get_next()
	d.list_dir_end()
	return out

func get_slot_directory(slot: String) -> String:
	return DIR.plus_file(slot)

func get_slot_info(slot: String) -> Dictionary:
	var dir := get_slot_directory(slot)
	var info = UFile.load_json(dir.plus_file("slot.json"), {})
	var preview = UFile.load_image(dir.plus_file("preview.png"))
	info.slot = slot
	info.preview = preview
	info.dir_size = UFile.get_directory_size(dir)
	info.date_time = DateTime.create_from_datetime(info.time)
	return info

func load_slot(slot: String):
	pre_load.emit()
	
	var slot_path := get_slot_directory(slot)
	var state: Dictionary = UFile.load_from_resource(slot_path.plus_file("state.res"))
	_set_state.emit(state)
	
	loaded.emit()

func save_to_slot(slot: String):
	pre_save.emit()
	
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
	_get_state.emit(state)
	UFile.save_to_resource(slot_path.plus_file("state.res"), state)
	
	# save slot info
	var state_info := { time=Time.get_datetime_dict_from_system() }
	_get_state_info.emit(state_info)
	UFile.save_json(slot_path.plus_file("info.json"), state_info)
	
	saved.emit()
