@tool
extends EditorPlugin

const EditorHighlighter = preload("res://addons/sooty_engine/EditorHighlighter.gd")
var highligher = EditorHighlighter.new()

func _enter_tree() -> void:
	add_autoload_singleton("Global", "res://addons/sooty_engine/autoloads/Global.gd")
	add_autoload_singleton("SaveManager", "res://addons/sooty_engine/autoloads/SaveManager.gd")
	add_autoload_singleton("ModManager", "res://addons/sooty_engine/autoloads/ModManager.gd")
	add_autoload_singleton("State", "res://addons/sooty_engine/autoloads/State.gd")
	add_autoload_singleton("StringAction", "res://addons/sooty_engine/autoloads/StringAction.gd")
	add_autoload_singleton("Dialogues", "res://addons/sooty_engine/autoloads/Dialogues.gd")
	add_autoload_singleton("Persistent", "res://addons/sooty_engine/autoloads/Persistent.gd")
	
	var es: EditorSettings = get_editor_interface().get_editor_settings()
	var fs = es.get_setting("docks/filesystem/textfile_extensions")
	if not "soot" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soot")
	get_editor_interface().get_script_editor().register_syntax_highlighter(highligher)

func _exit_tree() -> void:
	remove_autoload_singleton("Global")
	remove_autoload_singleton("SaveManager")
	remove_autoload_singleton("ModManager")
	remove_autoload_singleton("State")
	remove_autoload_singleton("StringAction")
	remove_autoload_singleton("Dialogues")
	remove_autoload_singleton("Persistent")
	
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(highligher)
