@tool
extends EditorPlugin

const SootHighlighter = preload("res://addons/sooty_engine/dialogue/SootHighlighter.gd")
var highligher = SootHighlighter.new()
const AUTOLOADS := ["Sooty", "Global", "Mods", "State", "Persistent", "Dialogues", "DialogueStack"]

func _enter_tree() -> void:
	for id in AUTOLOADS:
		add_autoload_singleton(id, "res://addons/sooty_engine/autoloads/%s.gd" % id)
#	add_autoload_singleton("Sooty", "res://addons/sooty_engine/autoloads/Sooty.gd")
#	add_autoload_singleton("Global", "res://addons/sooty_engine/autoloads/Global.gd")
#	add_autoload_singleton("Mods", "res://addons/sooty_engine/autoloads/Mods.gd")
#	add_autoload_singleton("State", "res://addons/sooty_engine/autoloads/State.gd")
#	add_autoload_singleton("Persistent", "res://addons/sooty_engine/autoloads/Persistent.gd")
#	add_autoload_singleton("Dialogues", "res://addons/sooty_engine/autoloads/Dialogues.gd")
#	add_autoload_singleton("DialogueStack", "res://addons/sooty_engine/autoloads/DialogueStack.gd")
	
	var es: EditorSettings = get_editor_interface().get_editor_settings()
	var fs = es.get_setting("docks/filesystem/textfile_extensions")
	if not "soot" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soot")
	get_editor_interface().get_script_editor().register_syntax_highlighter(highligher)

func _exit_tree() -> void:
	for id in AUTOLOADS:
		remove_autoload_singleton(id)
#	remove_autoload_singleton("Sooty")
#	remove_autoload_singleton("Global")
#	remove_autoload_singleton("Mods")
#	remove_autoload_singleton("State")
#	remove_autoload_singleton("Persistent")
#	remove_autoload_singleton("Dialogues")
#	remove_autoload_singleton("DialogueStack")
	
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(highligher)
