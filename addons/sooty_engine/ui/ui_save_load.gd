extends Node

@export var save_mode := true
#var slot_names: PackedStringArray
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
#	slot_names = Saver.get_slot_names()
	_update_page()
	
	for i in pages.get_child_count():
		pages.get_child(i).pressed.connect(set.bind("page", i))

func _select_slot(index: int):
	var slot := "%s_%s" % [page, index] # slot_names[index]
	
	# save?
	if save_mode:
		if Saver.has_slot(slot):
			pass # TODO: Are you sure?
		
		await Saver.save_slot(slot)
		_update_slot(index)
	# load?
	else:
		Saver.load_slot(slot)

func _update_page():
	for i in slots_per_page:
		_update_slot(i)

func _update_slot(index: int):
	var info := Saver.get_slot_info("%s_%s" % [page, index])
	buttons.get_child(index).set_info(info)
