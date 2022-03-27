extends "res://addons/sooty_engine/autoloads/base_state.gd"

const GROUP_PERSISTENT := "has_persistent_state"
const SAVE_PATH := "user://persistent.res"

func _get_subdir() -> String:
	return "persistent"

func _init() -> void:
	super._init()
	if not Engine.is_editor_hint():
		Saver._get_persistent.connect(_save_state)
		Saver._set_persistent.connect(_load_state)
		changed.connect(_trigger_save)

func _trigger_save(_x):
	_changed = false
	Saver.save_persistent()

#func _post_init():
#	super._post_init()
#	_load()
#
#func _save():
#	var out := {main=_get_changed_states(), other={}}
#	for node in get_tree().get_nodes_in_group(GROUP_PERSISTENT):
#		out.other[node.name] = node.get_persistent_state()
#	UFile.save_to_resource(SAVE_PATH, out)
#
#func _load():
#	var data = UFile.load_from_resource(SAVE_PATH)
#	if data:
#		pass
