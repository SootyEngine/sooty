extends Node

const VERSION := "0.1_alpha"

const S_FLOW_GOTO := "=>"
const S_FLOW_CALL := "=="

const S_ACTION_EVAL := "~"
const S_ACTION_STATE := "$"
const S_ACTION_GROUP := "@"

func _init() -> void:
	add_to_group("sa:sooty_version")

func sooty_version():
	return "[%s]%s[]" % [Color.TOMATO, VERSION]
