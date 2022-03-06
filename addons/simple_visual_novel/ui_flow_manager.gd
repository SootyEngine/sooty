extends Node

@export var stack: Resource = DialogueStack.new()
@export var waiting_for_option := false
@export var current := "bottom"
@export var pausers := []

func _init() -> void:
	add_to_group("flow_manager")
	add_to_group("sa:printer")
	add_to_group("sa:wait")
	stack.is_waiting = is_waiting

func add_pauser(n: Node):
	if not n in pausers:
		n.add_to_group("pauser", true)
		pausers.append(n)

func remove_pauser(n: Node):
	if n in pausers:
		n.remove_from_group("pauser")
		pausers.erase(n)

func _process(_delta: float) -> void:
	stack.tick()

func is_waiting() -> bool:
	return len(pausers) > 0

const _printer_ARGS := [""]
func printer(id: String):
	current = id

const _wait_ARGS := [""]
func wait(time: float):
	add_pauser(self)
	get_tree().create_timer(time).timeout.connect(remove_pauser.bind(self))

func _ready() -> void:
	stack.started.connect(_on_started)
	stack.finished.connect(_on_finished)
	stack.on_line.connect(_on_text)
	stack.on_action.connect(_on_action)
	_startup.call_deferred()

func _startup():
	if not stack._started:
		stack.start("test")

func _on_started():
	print("STARTED")

func _on_finished():
	print("FINISHED")
	print(State._get_changed_states())

func _on_text(d: DialogueLine):
	get_node(current).show_line(d)

func _on_action(s: String):
	StringAction.do(s)

func print_pausers():
	if len(pausers):
		print("WAITING FOR:")
		for item in pausers:
			print("\t", item)
