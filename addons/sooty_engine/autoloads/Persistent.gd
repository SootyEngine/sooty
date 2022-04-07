@tool
extends "res://addons/sooty_engine/autoloads/state_manager.gd"

func _get_subdir() -> String:
	return "persistent"

func _connect_to_signals():
	super._connect_to_signals()
	Saver._get_persistent.connect(_save_state)
	Saver._set_persistent.connect(_load_state)
	changed.connect(_trigger_save)

func _trigger_save(_x):
	_changed = false
	Saver.save_persistent()
