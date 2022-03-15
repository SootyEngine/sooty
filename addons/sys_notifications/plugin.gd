@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Notify", "res://addons/sys_notifications/autoloads/Notify.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("Notify")
