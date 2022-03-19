extends Control

signal selected(option: DialogueLine)

@export var _button_parent: NodePath = ""
@export var _button_prefab: NodePath = ""
@export var _selection_indicator: NodePath = ""
@onready var button_parent: Node = get_node(_button_parent)
@onready var button_prefab: Node = get_node(_button_prefab)
@onready var selection_indicator: Node = get_node(_selection_indicator)

var _can_select := false
var _shown := false
var _tween: Tween
var _options: Array
var _options_passing: Array

var hovered := 0:
	set(h):
		h = wrapi(h, 0, button_parent.get_child_count())
		if hovered != h:
			hovered = h
			
			for i in button_parent.get_child_count():
				var n: Control = button_parent.get_child(i)
				n.hovered = i == h
		
		var n: Control = button_parent.get_child(hovered)
		if n:
			selection_indicator.position.x = n.rect_position.x + 14
			selection_indicator.position.y = n.rect_position.y + 16

func _ready() -> void:
	visible = false
	button_parent.remove_child(button_prefab)

func _input(event: InputEvent) -> void:
	if _shown:
		if event.is_action_pressed("ui_up"):
			hovered -= 1
		elif event.is_action_pressed("ui_down"):
			hovered += 1
		elif event.is_action_pressed("continue"):
			_select(_options[hovered])

func has_options() -> bool:
	return len(_options_passing) > 0

func _set_line(line: DialogueLine):
	if line.has_options():
		_options = line.get_options()
		_options_passing = _options.filter(func(x): return x.passed)
	else:
		_options = []
		_options_passing = []
	
	_can_select = false
	_shown = true
	visible = true
	modulate.a = 0.0
	get_tree().create_timer(0.5).timeout.connect(set.bind("_can_select", true))
	_create_options()

func _show_options():
	modulate.a = 1.0
	
func _create_options():
	rect_size.y = 0.0
	
	for i in len(_options):
		var option = _options[i]
		var button := button_prefab.duplicate()
		button_parent.add_child(button)
		button.set_owner(owner)
		button.set_option(option)
		button.pressed.connect(_select.bind(option))
		button.hovered = i == 0
	
	hovered = 0
	hide()
	show()

func _select(option: DialogueLine):
	if not _can_select:
		return
	
	for button in button_parent.get_children():
		button_parent.remove_child(button)
		button.queue_free()
	
	DialogueStack.select_option(option)
	selected.emit(option)
	visible = false
	_shown = false
	_can_select = false

func _create_tween() -> Tween:
	if _tween:
		_tween.stop()
	_tween = get_tree().create_tween()
	return _tween
