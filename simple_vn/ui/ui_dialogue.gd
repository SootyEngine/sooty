extends Control

@export var _from: NodePath
@export var _text: NodePath
@export var _options: NodePath
@export var _option: NodePath
@export var _option_container: NodePath
@onready var from: RichTextLabel2 = get_node(_from)
@onready var text: RichTextAnimation = get_node(_text)
@onready var options: Control = get_node(_options)
@onready var option: Control = get_node(_option)
@onready var option_container: Control = get_node(_option_container)

@export var waiting_for_option := false

# prevent user from accidentally skipping options before reading
var wait_timer := 0.0

var hovered := 0:
	set(h):
		h = wrapi(h, 0, option_container.get_child_count()-1)
		prints(h, option_container.get_child_count())
		if hovered != h:
			hovered = h
			var index := 0
			for op in option_container.get_children():
				if op != option:
					op.hovered = index == h
					index += 1

func _ready() -> void:
	visible = false
	option.visible = false
	options.visible = false
	
	text.nicer_quotes_format = "[w=.5;q;tomato][dim]“[]%s[dim]”[][][w=.5]"
	text.quote_started.connect(_quote_started)
	text.quote_ended.connect(_quote_ended)
	
	resized.connect(_resized)
	_resized()

func _resized():
	print("resized")
	var ts = $backing.get_texture().get_size()
	$backing.global_position = get_global_rect().position
	$backing.scale = get_rect().size / ts

func _quote_started():
	print("QUOTE STARTED")

func _quote_ended():
	print("QUOTE ENDED")

func _input(_event: InputEvent) -> void:
	if visible and Input.is_action_just_pressed("continue"):
		if waiting_for_option:
			select_option(option_container.get_child(hovered+1).option)
		
		else:
			if not text.is_finished():
				text.advance()
			else:
				end()

func _process(delta: float) -> void:
	if wait_timer >= 0.0:
		wait_timer -= delta
	
	if Input.is_action_just_pressed("ui_up"):
		hovered -= 1
	elif Input.is_action_just_pressed("ui_down"):
		hovered += 1

func show_line(d: DialogueLine, who: Variant):
	get_tree().get_first_node_in_group("flow_manager").add_pauser(self)
	text.set_bbcode(d.text)
	if who is String:
		from.visible = true
		from.set_bbcode(who)
	else:
		from.visible = false
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
	rect_size.y = 0.0
	hovered = -1
	
	for i in len(odata):
		var opp := option.duplicate()
		option_container.add_child(opp)
		opp.visible = true
		opp.set_option(odata[i])
		opp.pressed.connect(select_option.bind(odata[i]))
		opp.set_owner(owner)
	
#	_update_size.call_deferred()
	wait_timer = 1.0
	
#func _update_size():
#	rect_size.y = option_container.rect_size.y
#	rect_position.y = get_viewport_rect().size.y - rect_size.y

func select_option(o: DialogueLine):
	if wait_timer >= 0:
		return
	
	options.visible = false
	waiting_for_option = false
	
	for child in option_container.get_children():
		if child != option:
			option_container.remove_child(child)
			child.queue_free()
	
	get_tree().get_first_node_in_group("flow_manager").stack.select_option(o)
	end()