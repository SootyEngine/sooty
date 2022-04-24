@tool
extends EditorPlugin

const AUTOLOADS := [
	"Global",
	"DataManager",
	"ModManager",
	"Settings",
	"SceneManager",
	"SaveManager",
	"Persistent",
	"State",
	"StringAction",
	"MusicManager",
	"SFXManager",
	"Dialogue"
]

const EDITOR = preload("res://addons/sooty_engine/ui/ui_map_gen.tscn")
var editor

const ChapterPanel = preload("res://addons/sooty_engine/editor/chapter_panel.tscn")
var chapter_panel: Node

func _get_plugin_name() -> String:
	return "Sooty"

func _enter_tree() -> void:
	# load all autoloads in order.
	for id in AUTOLOADS:
		add_autoload_singleton(id, "res://addons/sooty_engine/autoloads/%s.gd" % id)
	
	# add .soot to the allowed textfile extensions.
	var editor_settings: EditorSettings = get_editor_interface().get_editor_settings()
	var fs: Array = editor_settings.get_setting("docks/filesystem/textfile_extensions").split(",")
	var changed := false
	for type in Soot.ALL_EXTENSIONS:
		if not type in fs:
			changed = true
			fs.append(type)
	if changed:
		editor_settings.set_setting("docks/filesystem/textfile_extensions", ",".join(fs))
	
	# add extensions to the file search
	var sof := "editor/script/search_in_file_extensions"
	var extensions: PackedStringArray = ProjectSettings.get_setting(sof)
	changed = false
	for ext in Soot.ALL_EXTENSIONS:
		if not ext in extensions:
			changed = true
			extensions.append(ext)
	if changed:
		ProjectSettings.set_setting(sof, extensions)
	
	# signal for auto adding highlighters based on file type
	var se: ScriptEditor = get_editor_interface().get_script_editor()
	se.editor_script_changed.connect(_editor_script_changed)
	
	# chapter overview side panel
	chapter_panel = ChapterPanel.instantiate()
	chapter_panel.plugin_instance_id = get_instance_id()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, chapter_panel)
	
#	var rf: EditorFileSystem = get_editor_interface().get_resource_filesystem()
#	rf.filesystem_changed.connect(func(): print("filesystem changed"))
#	rf.resources_reload.connect(func(f): print("reloading: ", f))
#	rf.resources_reimported.connect(func(f): print("reimporting: ", f))

# find a code editor for a given text file.
func get_code_edit(path: String) -> CodeEdit:
	for e in get_editor_interface().get_script_editor().get_open_script_editors():
		if e.has_meta("_edit_res_path") and e.get_meta("_edit_res_path") == path:
			return e.get_base_editor()
	return null

# open a text editor
func edit_text_file(path: String, line := 0, column := 0):
	get_editor_interface().select_file(path)
	# open in editor
	get_editor_interface().edit_resource(load(path))
	# move to the appropriate line
	var code_edit := get_code_edit(path)
	if code_edit:
		code_edit.set_caret_line.call_deferred(line, true)
		code_edit.set_line_as_center_visible.call_deferred(line)

func _editor_script_changed(s):
	# auto add highlighters
	for e in get_editor_interface().get_script_editor().get_open_script_editors():
		if e.has_meta("_edit_res_path") and not e.has_meta("_soot_hl"):
			# set a flag so we don't constantly apply the highlighters.
			e.set_meta("_soot_hl", true)
			
			var se: ScriptEditorBase = e
			var c: CodeEdit = se.get_base_editor()
			var rpath: String = se.get_meta("_edit_res_path")
			var extension: String = rpath.get_extension()
			match extension:
				# .soot dialogue files
				# .sola language files
				Soot.EXT_DIALOGUE, Soot.EXT_LANG, Soot.EXT_TEXT:
					c.set_script(load("res://addons/sooty_engine/editor/DialogueEditor.gd"))
					c.set.call_deferred("plugin_instance_id", get_instance_id())
					
					# for markdown, add line wrapping
					if extension == Soot.EXT_TEXT:
						c.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
				
				# .soda data files
				Soot.EXT_DATA:
					c.set_script(load("res://addons/sooty_engine/editor/DataEditor.gd"))
					c.set.call_deferred("plugin_instance_id", get_instance_id())

func _exit_tree() -> void:
#	if editor:
#		editor.queue_free()
	
# 	if editor:
# 		remove_control_from_docks(editor)
	
	if chapter_panel:
		chapter_panel.queue_free()
	
	for i in range(len(AUTOLOADS)-1, -1, -1):
		remove_autoload_singleton(AUTOLOADS[i])
