extends "res://addons/sooty_engine/autoloads/base_state.gd"

func _init() -> void:
	add_to_group(SaveManager.GROUP_SAVE_STATE)

func _ready() -> void:
	super._ready()
	print("[States]")
	for script_path in UFile.get_files("res://states", ".gd"):
		var mod = install(script_path)
		print("\t- ", script_path)

func get_save_state() -> Dictionary:
	return _get_changed_states()
