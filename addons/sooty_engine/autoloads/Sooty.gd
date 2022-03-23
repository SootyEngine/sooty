extends Node

const VERSION := "0.1_alpha"

var debug_show_hidden_options := false

func _init() -> void:
	add_to_group("sa:sooty_version")

func sooty_version():
	return "[%s]%s[]" % [Color.TOMATO, VERSION]
