extends Node

@export var stack: Resource = DialogueStack.new()

@export var start := "MAIN.START"
@export var _caption := "bottom"
@export var _pausers := []
var speaker_cache := []

func _init() -> void:
	add_to_group("flow_manager")
	add_to_group("sa:scene")
	add_to_group("sa:goto")
	add_to_group("sa:caption")
	add_to_group("sa:wait")

func _ready() -> void:
	add_pauser(self)
	Fader.create(null, {anim="in", done=remove_pauser.bind(self)})
	
	stack.started.connect(_on_started)
	stack.finished.connect(_on_finished)
	stack.on_line.connect(_on_text)
	stack.on_action.connect(_on_action)
	_startup.call_deferred()

func goto(id: String = ""):
	Fader.create(_goto.bind(id))

func _goto(id: String):
	get_tree().change_scene("res://addons/menu_scenes/ui_%s.tscn" % id)

func scene(id: String):
	add_pauser(self)
	Fader.create(_scene.bind(id), {done=remove_pauser.bind(self)})

func _scene(id: String):
	# remove previous scenes
	for child in $scene.get_children():
		$scene.remove_child(child)
		child.queue_free()
	
	var sc := find_scene(id)
	if sc:
		$scene.add_child(sc.instantiate())
	else:
		push_error("No scene '%s' found." % id)

func find_scene(id: String) -> PackedScene:
	for p in ["res://story_scenes/%s.tscn", "res://story_scenes/%s.scn"]:
		var path: String = p % id
		if UFile.file_exists(path):
			return load(path)
	return null
	
func _startup():
	if not stack._started:
		stack.start(start)

func add_pauser(n: Node) -> bool:
	if not n in _pausers:
		stack.wait = true
		_pausers.append(n)
		return true
	return false

func remove_pauser(n: Node):
	if n in _pausers:
		_pausers.erase(n)
		if not len(_pausers):
			stack.wait = false

func _process(_delta: float) -> void:
	stack.tick()

func caption(id: String):
	_caption = id

const _wait_ARGS := [""]
func wait(time: float):
	add_pauser(self)
	get_tree().create_timer(time).timeout.connect(remove_pauser.bind(self))

func _on_started():
	print("STARTED")

func _on_finished():
	print("FINISHED ", stack._history)
	print("STATE")
	UDict.log(State._get_state())
	print("CHANGED STATE")
	UDict.log(State._get_changed_states())
	speaker_cache.clear()
	if len(stack._history) and stack._history[-1] != "MAIN.END":
		stack.goto("MAIN.END")

func _on_text(d: DialogueLine):
	var from = d.from
	if from == null:
		pass
	elif from != "":
		speaker_cache.append(from)
	elif len(speaker_cache):
		from = speaker_cache[-1]
	
	if from is String:
		if UString.is_wrapped(from, '"'):
			from = UString.unwrap(from, '"')
		elif State._has(from):
			var val = State._get(from)
			if val is Object and val.has_method("to_string"):
				from = val.to_string()
			else:
				from = str(val)
	
	$flow_manager.get_node(_caption).show_line(d, from)

func _on_action(s: String):
	print("DO ACTION", s)
	StringAction.do(s)

func print_pausers():
	if len(_pausers):
		print("WAITING FOR:")
		for item in _pausers:
			print("\t", item)
