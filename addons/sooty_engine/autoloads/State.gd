extends "res://addons/sooty_engine/autoloads/base_state.gd"

func _init() -> void:
	add_to_group(SaveManager.GROUP_SAVE_STATE)

func _ready() -> void:
	super._ready()
	install("res://state.gd")

func get_save_state() -> Dictionary:
	return _get_changed_states()
