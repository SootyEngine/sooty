@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("SaveManager", "res://addons/sys_save/autoloads/SaveManager.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("SaveManager")
