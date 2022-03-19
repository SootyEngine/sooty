@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("SimpleVN", "res://addons/simple_vn/autoloads/simple_vn.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("SimpleVN")
