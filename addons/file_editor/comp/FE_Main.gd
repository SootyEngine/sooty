@tool
extends Node
class_name FE_Main

@export var _is_plugin := false

@export var _files: NodePath
@export var _editors: NodePath
@export var _confirmation_dialogue: NodePath
@export var _file_dialogue: NodePath
@onready var files: FE_Files = get_node(_files)
@onready var editors: FE_Editors = get_node(_editors)
@onready var confirmation_dialogue: ConfirmationDialog = get_node(_confirmation_dialogue)
@onready var file_dialogue: FileDialog = get_node(_file_dialogue)

func _set_as_plugin():
	_is_plugin = true

func is_plugin_hint() -> bool:
	return _is_plugin
