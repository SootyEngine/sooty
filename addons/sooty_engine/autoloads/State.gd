extends "res://addons/sooty_engine/autoloads/base_state.gd"

func _ready() -> void:
	super._ready()
	add_mod("res://state.gd")

func add_mod(path: String):
	var mod: Node = load(path).new()
	add_child(mod)
