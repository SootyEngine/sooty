@tool
extends EditorSyntaxHighlighter

var hl := preload("res://addons/sooty_engine/data/DataHighlighterRuntime.gd").new()

func _get_name() -> String:
	return "Soda"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	return hl._get_line_syntax_highlighting2(get_text_edit().get_line(line))
