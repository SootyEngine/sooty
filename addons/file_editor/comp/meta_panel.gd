@tool
extends Control

@onready var shortcut_toggle:Shortcut = FE_Util.str_to_shortcut("ctrl+m")

func _ready() -> void:
	visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if FE_Util.is_shortcut(event, shortcut_toggle):
#		print(event)
#	if shortcut_toggle.matches_event(event):
		visible = not visible
		get_viewport().set_input_as_handled()
