extends "res://addons/sooty_engine/autoloads/state_manager.gd"

func _get_subdir() -> String:
	return "settings"

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		Saver._get_persistent.connect(_save_state)
		Saver._set_persistent.connect(_load_state)
		changed.connect(_trigger_save)

func _trigger_save(_x):
	_changed = false
	Saver.save_persistent()
