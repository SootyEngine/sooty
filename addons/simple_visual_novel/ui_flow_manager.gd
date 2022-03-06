extends Node

@export var stack: Resource = DialogueStack.new()

@export var _printer := "bottom"
@export var _pausers := []

func _init() -> void:
	add_to_group("flow_manager")
	add_to_group("sa:printer")
	add_to_group("sa:wait")

#func is_pauser(n: Node) -> bool:
#	return n in _pausers

func add_pauser(n: Node) -> bool:
	if not n in _pausers:
		stack.wait = true
#		n.add_to_group("pauser", true)
		_pausers.append(n)
		return true
	return false

func remove_pauser(n: Node):
	if n in _pausers:
#		n.remove_from_group("pauser")
		_pausers.erase(n)
		if not len(_pausers):
			stack.wait = false

func _process(_delta: float) -> void:
	stack.tick()

const _printer_ARGS := [""]
func printer(id: String):
	_printer = id

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
	get_node(_printer).show_line(d)

func _on_action(s: String):
	StringAction.do(s)

func print_pausers():
	if len(_pausers):
		print("WAITING FOR:")
		for item in _pausers:
			print("\t", item)
