@tool
extends EditorPlugin

const AUTOLOADS := ["Sooty", "Global", "Mods", "Saver", "Persistent", "State", "StringAction", "Music", "SFX", "Dialogues", "DialogueStack"]
const HIGHLIGHTER = preload("res://addons/sooty_engine/dialogue/SootHighlighter.gd")
var highlighter = HIGHLIGHTER.new()

func _enter_tree() -> void:
	for id in AUTOLOADS:
		add_autoload_singleton(id, "res://addons/sooty_engine/autoloads/%s.gd" % id)
	
	var es: EditorSettings = get_editor_interface().get_editor_settings()
	var fs = es.get_setting("docks/filesystem/textfile_extensions")
	if not "soot" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soot")
	
	var se: ScriptEditor = get_editor_interface().get_script_editor()
	se.register_syntax_highlighter(highlighter)

func _exit_tree() -> void:
	for id in AUTOLOADS:
		remove_autoload_singleton(id)
	
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(highlighter)
