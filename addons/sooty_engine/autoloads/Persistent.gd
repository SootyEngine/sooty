@tool
extends StateManagerBase

func _get_subdir() -> String:
	return "persistent"

func _connect_to_signals():
	super._connect_to_signals()
	SaveManager._get_persistent.connect(_save_state)
	SaveManager._set_persistent.connect(_load_state)
	changed.connect(_trigger_save)

func _trigger_save(_x):
	_has_changed = false
	SaveManager.save_persistent()
