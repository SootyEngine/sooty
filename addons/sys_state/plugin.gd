@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("State", "res://addons/sys_state/autoloads/State.gd")
	add_autoload_singleton("Persistent", "res://addons/sys_state/autoloads/Persistent.gd")
	add_autoload_singleton("StringAction", "res://addons/sys_state/autoloads/StringAction.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("State")
	remove_autoload_singleton("Persistent")
	remove_autoload_singleton("StringAction")
