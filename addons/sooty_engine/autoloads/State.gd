@tool
extends StateManagerBase

func _get_subdir() -> String:
	return "states"

func _connect_to_signals():
	super._connect_to_signals()
	SaveManager._get_state.connect(_save_state)
	SaveManager._set_state.connect(_load_state)

func get_save_state() -> Dictionary:
	return _get_changed_states()


