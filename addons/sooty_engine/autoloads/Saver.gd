@tool
extends Node

const DIR := "user://saves"
const PATH_PERSISTENT := "user://persistent.res"
const FNAME_INFO := "info.json"
const FNAME_PREVIEW := "preview.png"
const FNAME_STATE := "state.res"
const FNAME_SCENE := "scene.scn"
const PREVIEW_SIZE_DIV_AMOUNT := 3.0 # How much to shrink preview image.

signal pre_save()
signal pre_load()
signal saved()
signal loaded()
signal _check_can_save(blocking: Array)
# internally collect all state data
signal _get_state(data: Dictionary)
signal _set_state(data: Dictionary)
# internall collect state info
signal _get_state_info(data: Dictionary)

signal pre_save_persistent()
signal _get_persistent(data: Dictionary)
signal saved_persistent()
signal pre_load_persistent()
signal _set_persistent(data: Dictionary)
signal loaded_persistent()

var _wait_timer := 0.0
var _last_save_slot := ""
var _timer := Timer.new()

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	await get_tree().process_frame
	Mods.loaded.connect(_mods_loaded)
	
	var d := Directory.new()
	if not d.dir_exists(DIR):
		d.make_dir(DIR)
	
	if not Engine.is_editor_hint():
		add_child(_timer)
		_timer.wait_time = 2.0
		_timer.timeout.connect(_save_persistent)

func has_last_save() -> bool:
	return _last_save_slot != "" and has_slot(_last_save_slot)

func load_last_save():
	load_slot(_last_save_slot)

func _mods_loaded():
	await get_tree().process_frame
	pre_load_persistent.emit()
	var data: Dictionary = UFile.load_from_resource(PATH_PERSISTENT, {})
	_last_save_slot = data.get("last_save_slot", _last_save_slot)
	_set_persistent.emit(data)
	loaded_persistent.emit()
	print("Loaded Persistent from user://persistent.tres.")

func save_persistent():
	_timer.start()

func _save_persistent():
	_timer.stop()
	pre_save_persistent.emit()
	var data := {}
	data["last_save_slot"] = _last_save_slot
	_get_persistent.emit(data)
	UFile.save_to_resource(PATH_PERSISTENT, data)
	# DEBUG
	UFile.save_to_resource("user://persistent.tres", data)
	saved_persistent.emit()
	print("Saved Persistent to user://persistent.tres.")

func get_all_saved_slots() -> PackedStringArray:
	return UFile.get_dirs(DIR)

func has_slot(slot: String) -> bool:
	return UFile.dir_exists(get_slot_directory(slot))

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
	
	await Scene.change_scene(state.current_scene, true)
	
	pre_load.emit()
	_set_state.emit(state)
	loaded.emit()
	print("Loaded Slot %s." % slot)

func temp_save(index := 0):
	save_slot("temp_%s" % index)

func auto_save(index := 0):
	save_slot("auto_%s" % index)

func save_slot(slot: String):
	var blocking_save := []
	_check_can_save.emit(blocking_save)
	if len(blocking_save):
		push_error("Can't save. Blocked by %s." % [blocking_save])
		return
	
	pre_save.emit()
	
	var slot_path := get_slot_directory(slot)
	
	var d := Directory.new()
	if not d.dir_exists(slot_path):
		d.make_dir(slot_path)
	
	# state data
	var state := {}
	state.current_scene = slot_path.plus_file("scene.tscn")#get_tree().current_scene.scene_file_path
	UFile.save_node(slot_path.plus_file(FNAME_SCENE), get_tree().current_scene)
	UFile.save_node(slot_path.plus_file("scene.tscn"), get_tree().current_scene) # debug
	
	_get_state.emit(state)
	UFile.save_to_resource(slot_path.plus_file(FNAME_STATE), state)
	# DEBUG
	UFile.save_to_resource(slot_path.plus_file("state.tres"), state)
	
	# save slot info
	var state_info := { time=Time.get_datetime_dict_from_system() }
	
	if State._has("save_caption"):
		state_info.save_caption = State._get("save_caption")
	
	if State._has("progress"):
		state_info.progress = State._get("progress")
	
	_get_state_info.emit(state_info)
	UFile.save_json(slot_path.plus_file(FNAME_INFO), state_info)
	
	# preview image
	if not Global._screenshot:
		Global.snap_screenshot()
	var img: Image = Global._screenshot.duplicate()
	var siz := img.get_size() / PREVIEW_SIZE_DIV_AMOUNT
	img.resize(ceil(siz.x), ceil(siz.y), Image.INTERPOLATE_LANCZOS)
	img.save_png(slot_path.plus_file(FNAME_PREVIEW))
	
	saved.emit()
	_last_save_slot = slot
	save_persistent()
	print("Saved Slot %s." % slot)
