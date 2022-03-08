@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Global", "res://addons/sooty_engine/autoloads/Global.gd")
	add_autoload_singleton("SaveManager", "res://addons/sooty_engine/autoloads/SaveManager.gd")
	add_autoload_singleton("ModManager", "res://addons/sooty_engine/autoloads/ModManager.gd")
	add_autoload_singleton("State", "res://addons/sooty_engine/autoloads/State.gd")
	add_autoload_singleton("StringAction", "res://addons/sooty_engine/autoloads/StringAction.gd")
	add_autoload_singleton("Dialogues", "res://addons/sooty_engine/autoloads/Dialogues.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("Global")
	remove_autoload_singleton("SaveManager")
	remove_autoload_singleton("ModManager")
	remove_autoload_singleton("State")
	remove_autoload_singleton("StringAction")
	remove_autoload_singleton("Dialogues")
