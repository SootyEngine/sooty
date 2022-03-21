extends Node

const DIR := "user://saves"
const FNAME_INFO := "info.json"
const FNAME_PREVIEW := "preview.png"
const FNAME_STATE := "state.res"
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

func get_all_saved_slots() -> PackedStringArray:
	return UFile.get_dirs(DIR)

func get_slot_directory(slot: String) -> String:
	return DIR.plus_file(slot)

func get_slot_info(slot: String) -> Dictionary:
	var dir := get_slot_directory(slot)
	if UFile.dir_exists(dir):
		var info = UFile.load_json(dir.plus_file(FNAME_INFO), {})
		var preview = UFile.load_image(dir.plus_file("preview.png"))
		info.slot = slot
		info.preview = preview
		info.dir_size = UFile.get_directory_size(dir)
		info.date_time = DateTime.create_from_datetime(info.time)
		return info
	else:
		return {}

func delete_slot(slot: String):
	var slot_path := get_slot_directory(slot)
	if UFile.dir_exists(slot_path):
		UFile.remove_directory(slot_path)

func load_slot(slot: String):
	var slot_path := get_slot_directory(slot)
	var state: Dictionary = UFile.load_from_resource(slot_path.plus_file(FNAME_STATE))
	
	var scene: Node = load(state.current_scene).instantiate()
	if get_tree().change_scene(state.current_scene) != OK:
		push_error("Couldn't load the scene.")
		return
	
	await get_tree().process_frame
	
	pre_load.emit()
	_set_state.emit(state)
	loaded.emit()

func save_slot(slot: String):
	pre_save.emit()
	
	var slot_path := get_slot_directory(slot)
	
	var d := Directory.new()
	if not d.dir_exists(slot_path):
		d.make_dir(slot_path)
	
	# state data
	var state := {}
	state.current_scene = get_tree().current_scene.scene_file_path
	_get_state.emit(state)
	UFile.save_to_resource(slot_path.plus_file(FNAME_STATE), state)
	# DEBUG
	UFile.save_to_resource(slot_path.plus_file("state.tres"), state)
	
	# save slot info
	var state_info := { time=Time.get_datetime_dict_from_system() }
	_get_state_info.emit(state_info)
	UFile.save_json(slot_path.plus_file(FNAME_INFO), state_info)
	
	# preview image
	var img: Image = SimpleVN.get_node("debug")._screenshot.duplicate()
	var siz := img.get_size() / PREVIEW_SIZE_DIV_AMOUNT
	img.resize(ceil(siz.x), ceil(siz.y), Image.INTERPOLATE_LANCZOS)
	img.save_png(slot_path.plus_file(FNAME_PREVIEW))
	
	saved.emit()
