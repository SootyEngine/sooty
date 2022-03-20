extends Node

@export var save_mode := false
var slot_names: PackedStringArray
var page := 0:
	set(p):
		if page != p:
			page = p
			_update_page()
var slots_per_page := 9

@export var _buttons: NodePath
@export var _pages: NodePath
@onready var buttons: GridContainer = get_node(_buttons)
@onready var pages: Container = get_node(_pages)

func _ready() -> void:
	slot_names = Saver.get_slot_names()
	_update_page()
	
	for i in pages.get_child_count():
		pages.get_child(i).pressed.connect(set.bind("page", i))

func _select_slot(index: int):
	var slot := slot_names[index]
	# save?
	if save_mode:
		if Saver.has_slot(slot):
			# Are you sure you want to save over?
			pass
		else:
			push_error("Saving isn't implemented yet.")
	# load?
	else:
		push_error("Loading isn't implemented yet.")

func _update_page():
	for i in slots_per_page:
		var slot_node := buttons.get_child(i)
		var slot_index = page * slots_per_page + i
		if slot_index >= 0 and slot_index < len(slot_names):
			var info := Saver.get_slot_info(slot_names[slot_index])
			slot_node.set_info(info)
		else:
			slot_node.set_info({})
