@tool
extends Node

const MAX_STEPS_PER_TICK := 20 # Safety limit, in case of excessive loops.
enum { STEP_GOTO, STEP_CALL }

signal started()
signal ended()
signal tick_started()
signal tick_ended()
signal flow_started(id: String)
signal flow_ended(id: String)
signal option_selected(option: DialogueLine)
signal on_line(text: DialogueLine)
signal _refresh() # called when dialogues were reloaded, and so we should clear the captions/options.

@export var _execute_mode := false # TODO: Implement this differently.
@export var _break := false # breaking from the flow, temporarilly.
@export var _active := false # currently in the middle of running?
@export var _stack := [] # current stack of flows, so we can return to a position in a previous flow.
@export var _halting_for := [] # objects that want the flow to _break
@export var _last_tick_stack := [] # stack of the previous tick, used for saving and rollback.

const S_FLOW_GOTO := "=>"
const S_FLOW_CALL := "=="

func _init(em := false) -> void:
	_execute_mode = em

func _ready():
	if not Engine.is_editor_hint() and not _execute_mode:
		Saver._get_state.connect(_save_state)
		Saver._set_state.connect(_load_state)
		Saver.pre_load.connect(_pre_load)
		Global.started.connect(_on_start)
		Global.ended.connect(_on_end)
		Dialogues.reloaded.connect(_dialogues_reloaded)

func _save_state(state: Dictionary):
	state["DS"] = { active=_active, stack=_last_tick_stack }

func _load_state(state: Dictionary):
	_active = state["DS"].active
	_stack = state["DS"].stack

func _dialogues_reloaded():
	_refresh.emit()
	_stack = _last_tick_stack.duplicate(true)
	_break = false

func _pre_load():
	_clear()

func _clear():
	_active = false
	_break = false
	_halting_for = []
	_stack.clear()

func _on_start():
	if has("MAIN.START"):
		execute("MAIN.START")

func _on_end():
	_clear()
	if has("MAIN.END"):
		execute("MAIN.END")

func halt(halter: Object):
	if not halter in _halting_for:
		_halting_for.append(halter)
		_break = true

func unhalt(halter: Object):
	if halter in _halting_for:
		_halting_for.erase(halter)
		if not len(_halting_for):
			_break = false
		else:
			print("WAITING FOR ", _halting_for)

func is_active() -> bool:
	return _active

func has_steps() -> bool:
	return len(_stack) != 0

func get_current_dialogue() -> Dialogue:
	return null if not len(_stack) else Dialogues.get_dialogue(_stack[-1].did)

func _process(delta: float) -> void:
	tick()

func start(id: String):
	if _active:
		push_warning("Already started.")
		return
	
	# start dialogue
	if "." in id:
		goto(id, STEP_GOTO)
	
	# go to first flow of dialogue
	else:
		var d := Dialogues.get_dialogue(id)
		if not d.has_flows():
			push_error("No flows in '%s'." % id)
		else:
			var first = Dialogues.get_dialogue(id).flows.keys()[0]
			goto("%s.%s" % [id, first], STEP_GOTO)

func can_do(command: String) -> bool:
	return command.begins_with(S_FLOW_GOTO) or command.begins_with(S_FLOW_CALL)

func do(command: String):
	if command.begins_with(S_FLOW_GOTO):
		goto(command.trim_prefix(S_FLOW_GOTO).strip_edges(), STEP_GOTO)
	elif command.begins_with(S_FLOW_CALL):
		goto(command.trim_prefix(S_FLOW_CALL).strip_edges(), STEP_CALL)
	else:
		push_error("Don't know what to do with '%s'." % command)

func has(id: String) -> bool:
	var p := id.split(".", true, 1)
	if not Dialogues.has(p[0]):
		return false
	var d := Dialogues.get_dialogue(p[0])
	if not d.has_flow(p[1]):
		return false
	return true

func goto(did_flow: String, step_type: int = STEP_GOTO) -> bool:
	var p := did_flow.split(".", true, 1)
	var did := p[0]
	var flow := p[1]
	
	if not Dialogues.has(did):
		push_error("No dialogue %s." % did)
		return false
	
	var d := Dialogues.get_dialogue(did)
	if not d.has_flow(flow):
		push_error("No flow '%s' in '%s'." % [flow, did])
		return false
	
	var lines := d.get_flow_lines(flow)
	if not len(lines):
		push_error("Can't find lines for %s." % flow)
		return false
	
	# if the stack is cleared, it means this was a "goto" not a "call"
	if step_type == STEP_GOTO:
		while len(_stack):
			_pop()
	
	_push(did, flow, lines, step_type)
	return true

# select an option, adding it's lines to the stack
func select_option(option: DialogueLine):
	var o := option._data
	if "then" in o:
		_push(option._dialogue_id, "%OPTION%", o.then, STEP_CALL)
#	await get_tree().process_frame
	option_selected.emit(option)

func _pop():
	var last: Dictionary = _stack.pop_back()
	if last.type == STEP_GOTO:
		# let everyone know a flow ended
		flow_ended.emit("%s.%s" % [last.did, last.flow])

func _push(did: String, flow: String, lines: Array, type: int):
	_stack.append({ did=did, flow=flow, lines=lines, type=type, step=0 })
	if type == STEP_GOTO:
		flow_started.emit("%s.%s" % [did, flow])

func tick():
	if _break:
		return
	
	if not _active and has_steps():
		_active = true
		started.emit()
	
	if _active and not has_steps():
		_active = false
		ended.emit()
	
	if has_steps() and not _break:
		_last_tick_stack = _stack.duplicate(true)
		tick_started.emit()
	else:
		return
	
	var safety := MAX_STEPS_PER_TICK
	while has_steps() and not _break:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety! Increase MAX_STEPS_PER_TICK if necessary.", safety)
			break
		
		var line := pop_next_line()
		
		if not len(line) or not len(line.line):
			break
		
		match line.line.type:
			"action":
				StringAction.do(line.line.action)
				
			"goto":
				goto(line.line.goto, true)
				
			"call":
				goto(line.line.call, false)
				
			"text":
				if "action" in line.line:
					for a in line.line.action:
						StringAction.do(a)
				
				if not _execute_mode:
					on_line.emit(DialogueLine.new(line.did, line.line))
			
			_:
				push_warning("Huh? %s %s" % [line.line.keys(), line.line])
	
	tick_ended.emit()

# forcibly run a flow. usefuly for setting up scenes from a .soot file.
func execute(id: String):
	if has(id):
		var d = load("res://addons/sooty_engine/autoloads/DialogueStack.gd").new(true)
		d.start(id)
		d.tick()

func pop_next_line() -> Dictionary:
	var did_line := _pop_next_line()
	var did: String = did_line.did
	var flow: String = did_line.flow
	var line: Dictionary = did_line.line
	
	# only show lines that pass a test
	var safety := 100
	while len(line) and ("cond" in line or line.type in ["if", "match"]):
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		# 'if' 'elif' 'else' chain
		if line.type == "if":
			var d := Dialogues.get_dialogue(did)
			for i in len(line.conds):
				if State._test(line.conds[i]):
					_push(d.id, flow, line.cond_lines[i], STEP_CALL)
					break
		
		# match chain
		elif line.type == "match":
			var match_result = State._eval(line.match)
			for i in len(line.cases):
				var case = line.cases[i]
				var got = State._eval(case)
				if match_result == got or case == "_":
					_push(did, flow, line.case_lines[i], STEP_CALL)
					break
		
		elif "cond" in line and State._test(line.cond):
			break
		
		did_line = _pop_next_line()
		did = did_line.did
		flow = did_line.flow
		line = did_line.line
	
	return did_line

func _pop_next_line() -> Dictionary:
	if len(_stack):
		var step: Dictionary = _stack[-1]
		var dilg := Dialogues.get_dialogue(step.did)
		var line: Dictionary = dilg.get_line(step.lines[step.step])
		var out := { did=step.did, flow=step.flow, line=line }
		
		step.step += 1
		
		if step.step >= len(step.lines):
			_pop()
		
		return out
	
	else:
		push_error("Dialogue stack is empty.")
		return {}
