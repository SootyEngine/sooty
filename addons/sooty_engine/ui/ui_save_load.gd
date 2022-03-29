extends Node

@export var save_mode := true:
	set(v):
		save_mode = v
		_update_label()

var slots_per_page := 9
var page := "A":
	set(p):
		if page != p:
			page = p
			_update_label()
			_update_page()

func _update_label():
	label.text = ("Save - " if save_mode else "Load - ") + page

@export var _label: NodePath
@export var _buttons: NodePath
@export var _pages: NodePath
@export var _page_button: NodePath
@export var _confirmation: NodePath
@onready var label: Label = get_node(_label)
@onready var buttons: GridContainer = get_node(_buttons)
@onready var pages: Container = get_node(_pages)
@onready var page_button: Button = get_node(_page_button)
@onready var confirmation: ConfirmationDialog = get_node(_confirmation)

func _ready() -> void:
	_update_page()
	
	pages.remove_child(page_button)
	for c in UString.split_chars("abcdefghijklmnopqrstuvwxyz") + ["temp", "auto"]:
		var btn := page_button.duplicate()
		pages.add_child(btn)
		btn.text = c.capitalize()
		btn.pressed.connect(set.bind("page", c))

func _select_slot(index: int):
	var slot := "%s_%s" % [page, index]
	
	# save?
	if save_mode:
		# if slot exists, warn about overriding.
		if Saver.has_slot(slot):
			confirmation.title = "Warning!"
			confirmation.dialog_text = "Data exists at %s. Override it?" % slot
			confirmation.confirmed.connect(_save.bind(slot, index), Node.CONNECT_ONESHOT)
			confirmation.popup_centered()
		else:
			_save(slot, index)
	# load?
	else:
		if Saver.has_slot(slot):
			# if game is running, ask if sure about losing progress.
			if Global.active_game:
				confirmation.title = "Warning!"
				confirmation.dialog_text = "You will lose current games progress. Load anyway?"
				confirmation.confirmed.connect(Saver.load_slot.bind(slot), Node.CONNECT_ONESHOT)
				confirmation.popup_centered()
			else:
				Saver.load_slot(slot)
		else:
			push_warning("Empty slot: %s." % slot)

func _save(slot: String, index: int):
	await Saver.save_slot(slot)
	_update_slot(index)

func _update_page():
	for i in slots_per_page:
		_update_slot(i)

func _update_slot(index: int):
	var info := Saver.get_slot_info("%s_%s" % [page, index])
	buttons.get_child(index).set_info(info)
