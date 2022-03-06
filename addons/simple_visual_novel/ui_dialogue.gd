extends Control

@export var _from: NodePath
@export var _text: NodePath
@export var _options: NodePath
@export var _option: NodePath
@export var _option_container: NodePath
@onready var from: RichTextLabel3 = get_node(_from)
@onready var text: RichTextAnimation = get_node(_text)
@onready var options: Control = get_node(_options)
@onready var option: Control = get_node(_option)
@onready var option_container: Control = get_node(_option_container)

@export var waiting_for_option := false

func _ready() -> void:
	visible = false
	option.visible = false
	options.visible = false
	
	text.nicer_quotes_format = "[w=.5;q;tomato][dim]“[]%s[dim]”[][][w=.5]"
	text.quote_started.connect(_quote_started)
	text.quote_ended.connect(_quote_ended)

func _quote_started():
	print("QUOTE STARTED")

func _quote_ended():
	print("QUOTE ENDED")

func _input(event: InputEvent) -> void:
	if visible and Input.is_action_just_pressed("continue") and not waiting_for_option:
		if not text.is_finished():
			text.advance()
		else:
			end()

func show_line(d: DialogueLine):
	get_tree().get_first_node_in_group("flow_manager").add_pauser(self)
	text.set_bbcode(d.text)
	from.set_bbcode(d.from)
	visible = true
	
	if d.has_options():
		var op := d.get_options()
		if len(op):
			set_options(op)

func end():
	get_tree().get_first_node_in_group("flow_manager").remove_pauser(self)
	visible = false

func set_options(odata: Array):
	waiting_for_option = true
	options.visible = true
	for i in len(odata):
		var opp := option.duplicate()
		option_container.add_child(opp)
		opp.visible = true
		opp.set_option(odata[i])
		opp.pressed.connect(select_option.bind(odata[i]))
		opp.set_owner(owner)

func select_option(o: DialogueLine):
	options.visible = false
	waiting_for_option = false
	
	for child in option_container.get_children():
		if child != option:
			child.queue_free()
	
	get_tree().get_first_node_in_group("flow_manager").stack.select_option(o)
	end()
