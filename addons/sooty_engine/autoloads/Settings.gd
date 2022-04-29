@tool
extends "res://addons/sooty_engine/autoloads/StateManagerBase.gd"

func _get_subdir() -> String:
	return "settings"

func _ready():
	super._ready()
	if not Engine.is_editor_hint():
		Sooty.saver._get_persistent.connect(_save_state)
		changed.connect(_trigger_save)

func _trigger_save(_x):
	_has_changed = false
	Sooty.saver.save_persistent()
