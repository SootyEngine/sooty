@tool
extends EditorPlugin

const AUTOLOADS := ["Global", "Mods", "Settings", "Scene", "Saver", "Persistent", "State", "StringAction", "Music", "SFX", "Dialogue"]
const SOOT_HIGHLIGHTER = preload("res://addons/sooty_engine/dialogue/DialogueHighlighter.gd")
const DATA_HIGHLIGHTER = preload("res://addons/sooty_engine/data/DataHighlighter.gd")
const EDITOR = preload("res://addons/sooty_engine/ui/ui_map_gen.tscn")
var soot_highlighter := SOOT_HIGHLIGHTER.new()
var data_highlighter := DATA_HIGHLIGHTER.new()
var editor

#func _has_main_screen() -> bool:
#	return true

func _get_plugin_name() -> String:
	return "Sooty"

func _make_visible(visible: bool) -> void:
	if editor:
		editor.visible = visible

func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")

func _enter_tree() -> void:
	# load all autoloads in order.
	for id in AUTOLOADS:
		add_autoload_singleton(id, "res://addons/sooty_engine/autoloads/%s.gd" % id)
	
	# add .soot to the allowed textfile extensions.
	var es: EditorSettings = get_editor_interface().get_editor_settings()
	var fs = es.get_setting("docks/filesystem/textfile_extensions")
	if not ",soot" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soot")
	if not ",soda" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soda")
	
	var se: ScriptEditor = get_editor_interface().get_script_editor()
	# register syntax highlighter for drop down.
	se.register_syntax_highlighter(soot_highlighter)
	se.register_syntax_highlighter(data_highlighter)
	# track scripts opened/closed to can add highliter.
	se.editor_script_changed.connect(_editor_script_changed)
# 	
# 	editor = preload("res://addons/sooty_engine/ui/ui_map_gen.tscn").instantiate()
# 	editor.is_plugin_hint = true
# 	editor.plugin = self
# 	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, editor)
	

# find a code editor for a given text file.
func get_code_edit(path: String) -> CodeEdit:
	for e in get_editor_interface().get_script_editor().get_open_script_editors():
		if e.has_meta("_edit_res_path") and e.get_meta("_edit_res_path") == path:
			return e.get_base_editor()
	return null

func _editor_script_changed(s):
	# auto add highlighters
	for e in get_editor_interface().get_script_editor().get_open_script_editors():
		if e.has_meta("_edit_res_path") and not e.has_meta("_soot_hl"):
			# set a flag so we don't constantly call apply the highlighters.
			e.set_meta("_soot_hl", true)
			
			e = e as ScriptEditorBase
			
			var c: CodeEdit = e.get_base_editor()
			var rpath: String = e.get_meta("_edit_res_path")
			
			# .soot dialogue files
			if rpath.ends_with("." + Soot.EXT_DIALOGUE):
				c.symbol_lookup.connect(_symbol_lookup.bind(c))
				c.symbol_validate.connect(_symbol_validate.bind(c))
				c.symbol_lookup_on_click = true
				c.syntax_highlighter = soot_highlighter
			
			# .soda data files
			elif rpath.ends_with("." + Soot.EXT_DATA):
				c.syntax_highlighter = data_highlighter
			
			# .sola language files
			elif rpath.ends_with("." + Soot.EXT_LANG):
				c.syntax_highlighter = soot_highlighter

# go backwards through the lines and try to find the flow/path/to/this/node.
func _find_flow(next: String, line: int, c: CodeEdit) -> String:
	var deep := UString.count_leading(next, "\t")
	var out := []
	out.resize(deep)
	
	# go backwards collecting parent flows
	while line > 0:
		var s := c.get_line(line)
		var sdeep := UString.count_leading(s, "\t")
		if sdeep <= deep:
			var strip := s.strip_edges(true, false)
			if strip.begins_with("==="):
				out[sdeep] = strip.split("===", true, 1)[-1].strip_edges()
		line -= 1
	
	# add self to the path
	next = next.strip_edges()
	var head := UString.get_leading_symbols(next)
	next = next.trim_prefix(head).strip_edges()
	# add self at end
	
	# create path
	var path := Flow._get_flow_path("/".join(out), next)
	return path
	
func _symbol_validate(symbol: String, c: CodeEdit):
	var line_col := c.get_line_column_at_pos(c.get_local_mouse_pos())
	var line_text := c.get_line(line_col.y).strip_edges(true, false)
	var head := UString.get_leading_symbols(line_text)
	if head in ["===", "=>", "=="]:
		c.set_symbol_lookup_word_as_valid(true)
	else:
		c.set_symbol_lookup_word_as_valid(false)

func _symbol_lookup(symbol: String, line: int, column: int, c: CodeEdit):
	var line_col := c.get_line_column_at_pos(c.get_local_mouse_pos())
	var line_text := c.get_line(line_col.y)
	var head := UString.get_leading_symbols(line_text.strip_edges())
	match head:
		"=>", "==":
			var path := _find_flow(line_text, line, c)
			if path in Dialogue._flows:
				var meta: Dictionary = Dialogue._flows[path].M
				# select file in FileSystem
				get_editor_interface().select_file(meta.file)
				# open in editor
				get_editor_interface().edit_resource(load(meta.file))
				# move to the appropriate line
				var code_edit := get_code_edit(meta.file)
				code_edit.set_caret_line.call_deferred(meta.line, true)
				code_edit.set_line_as_center_visible.call_deferred(meta.line)
		"===":
			c.toggle_foldable_line(line)

func _exit_tree() -> void:
#	if editor:
#		editor.queue_free()
	
# 	if editor:
# 		remove_control_from_docks(editor)
	
	# remove .soot highlighter.
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(soot_highlighter)
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(data_highlighter)
	
	for i in range(len(AUTOLOADS)-1, -1, -1):
		remove_autoload_singleton(AUTOLOADS[i])
