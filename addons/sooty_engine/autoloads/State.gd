@tool
extends "res://addons/sooty_engine/autoloads/StateManagerBase.gd"

func _get_subdir() -> String:
	return "states"

func _ready():
	super._ready()
	_sooty.saver._get_state.connect(_save_state)
	_sooty.saver._set_state.connect(_load_state)

func get_save_state() -> Dictionary:
	return _get_changed_states()


