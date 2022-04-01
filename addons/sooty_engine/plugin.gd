@tool
extends EditorPlugin

const AUTOLOADS := ["Global", "Mods", "Settings", "Scene", "Saver", "Persistent", "State", "StringAction", "Music", "SFX", "Dialogues", "DialogueStack"]
const HIGHLIGHTER = preload("res://addons/sooty_engine/dialogue/DialogueHighlighter.gd")
var highlighter := HIGHLIGHTER.new()

func _enter_tree() -> void:
	# load all autoloads in order.
	for id in AUTOLOADS:
		add_autoload_singleton(id, "res://addons/sooty_engine/autoloads/%s.gd" % id)
	
	# add .soot to the allowed textfile extensions.
	var es: EditorSettings = get_editor_interface().get_editor_settings()
	var fs = es.get_setting("docks/filesystem/textfile_extensions")
	if not "soot" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soot")
	
	var se: ScriptEditor = get_editor_interface().get_script_editor()
	# register syntax highlighter for drop down.
	se.register_syntax_highlighter(highlighter)
	# track scripts opened/closed to can add highliter.
	se.editor_script_changed.connect(_editor_script_changed)

func _editor_script_changed(s):
	for e in get_editor_interface().get_script_editor().get_open_script_editors():
		if e.has_meta("_edit_res_path") and not e.has_meta("_soot_hl") and e.get_meta("_edit_res_path").ends_with(".soot"):
			e = e as ScriptEditorBase
			e.add_syntax_highlighter(highlighter)
			(e.get_base_editor() as CodeEdit).syntax_highlighter = highlighter
			e.set_meta("_soot_hl", true)

func _exit_tree() -> void:
	# remove .soot highlighter.
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(highlighter)
	
	for id in AUTOLOADS:
		remove_autoload_singleton(id)
	
