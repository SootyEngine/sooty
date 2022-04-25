@tool
extends "res://addons/sooty_engine/autoloads/StateManagerBase.gd"

func _get_subdir() -> String:
	return "persistent"

func _ready():
	super._ready()
	_sooty.saver._get_persistent.connect(_save_state)
	_sooty.saver._set_persistent.connect(_load_state)
	changed.connect(_trigger_save)

func _trigger_save(_x):
	_has_changed = false
	_sooty.saver.save_persistent()
