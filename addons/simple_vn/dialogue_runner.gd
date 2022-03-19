extends Node

@export var start := "MAIN.START"
var speaker_cache := []
var _wait_time := 0.0

func _init() -> void:
	add_to_group("flow_manager")

func wait(t := 1.0):
	_wait_time = t
	DialogueStack._break = true

func _ready() -> void:
	wait(0.25)
	Fader.create(null, {anim="in", time=.25})
	State.changed.connect(_state_changed)
	DialogueStack.started.connect(_on_started)
	DialogueStack.finished.connect(_on_finished)
	DialogueStack.on_line.connect(_on_text)
	_startup.call_deferred()

func _state_changed(property: String):
	match property:
		"caption_at":
			_caption_msg("hide")
			wait(0.5)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		var waiting_for := []
		_caption_msg("advance", waiting_for)
		if len(waiting_for):
#			print("WAITING FOR ", waiting_for)
			pass
		else:
			_caption_msg("hide")
			DialogueStack._break = false

func goto(id: String = ""):
	Fader.create(_goto.bind(id))

func _goto(id: String):
	get_tree().change_scene("res://addons/menu_scenes/ui_%s.tscn" % id)

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
	if not DialogueStack.is_active():
		DialogueStack.start(start)

func _process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		if _wait_time <= 0.0:
			_wait_time = 0.0
			DialogueStack._break = false
	
	DialogueStack.tick()

func _on_started():
	print("STARTED")

func _on_finished():
	print("FINISHED ", DialogueStack._history)
	print("=== STATE ===")
	UDict.log(State._get_state())
	print("=== CHANGED STATE ===")
	UDict.log(State._get_changed_states())
	speaker_cache.clear()
	if len(DialogueStack.history) and DialogueStack.history[-1] != "MAIN.END":
		DialogueStack.goto("MAIN.END")

func _on_text(line: DialogueLine):
	var from = line.from
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
	
	DialogueStack._break = true
	_caption_msg("show_line", {from=from, line=line})

func _caption_msg(msg_type: String, msg: Variant = null):
	Global.call_group_flags(SceneTree.GROUP_CALL_REALTIME, "caption", "_caption", [State.caption_at, msg_type, msg])
