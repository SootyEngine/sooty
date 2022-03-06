extends Node

@export var stack: Resource = DialogueStack.new()
@export var waiting_for_option := false
@export var current := "bottom"

func _init() -> void:
	add_to_group("sa:printer")

const _printer_ARGS := [""]
func printer(id: String):
	current = id

func _ready() -> void:
	stack.started.connect(_on_started)
	stack.finished.connect(_on_finished)
	stack.on_line.connect(_on_text)
	stack.on_action.connect(_on_action)
	stack.option_selected.connect(_option_selected)
	_startup.call_deferred()

func _startup():
	if not stack._started:
		stack.start("test")

func _option_selected(op: Dictionary):
	waiting_for_option = false
	stack.tick()

func _on_started():
	print("STARTED")

func _on_finished():
	print("FINISHED")
	$bottom/bottom/text.set_bbcode("")
	$bottom/bottom/from.set_bbcode("")
	$top/bottom/text.set_bbcode("")
	$top/bottom/from.set_bbcode("")
	print(State._get_changed_states())

func _on_text(d: DialogueLine):
	stack.wait()
	
	match current:
		"bottom":
			$bottom/bottom/text.set_bbcode(d.text)
			$bottom/bottom/from.set_bbcode(d.from)
		"top":
			$top/bottom/text.set_bbcode(d.text)
			$top/bottom/from.set_bbcode(d.from)
	
	if d.has_options():
		var op := d.get_options()
		if len(op):
			get_tree().get_first_node_in_group("sooty_options").set_options(op)
			waiting_for_option = true
	
func _on_action(s: String):
	StringAction.do(s)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("continue"):
		print("try continue")
		try_continue()

func try_continue():
	if waiting_for_option:
		print("Waiting for option.")
		return
	
	var waiting_for := get_tree().get_nodes_in_group("sooty_waiting")
	if len(waiting_for):
		print("WAITING FOR:")
		for item in waiting_for:
			print("\t", item)
	else:
		print("go!")
		stack.tick()
