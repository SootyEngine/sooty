@tool
extends CodeEdit

const SodaHighlighter = preload("res://addons/sooty_engine/editor/DataHighlighter.gd")

@export var plugin_instance_id: int

func _init() -> void:
	# custom highlighter
	syntax_highlighter = SodaHighlighter.new()
