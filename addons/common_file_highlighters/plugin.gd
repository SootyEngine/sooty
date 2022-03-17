@tool
extends EditorPlugin

const H_MD = preload("res://addons/common_file_highlighters/highlight_markdown.gd")
const H_CFG = preload("res://addons/common_file_highlighters/highlight_cfg.gd")
const H_JSON = preload("res://addons/common_file_highlighters/highlight_json.gd")
var h_md = H_MD.new()
var h_cfg = H_CFG.new()
var h_json = H_JSON.new()

func _enter_tree() -> void:
	for h in [h_md, h_cfg, h_json]:
		get_editor_interface().get_script_editor().register_syntax_highlighter(h)

func _exit_tree() -> void:
	for h in [h_md, h_cfg, h_json]:
		get_editor_interface().get_script_editor().unregister_syntax_highlighter(h)
