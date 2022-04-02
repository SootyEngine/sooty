extends Node

const MAX_STEPS_PER_TICK := 20 # Safety limit, in case of excessive loops.
enum { STEP_GOTO, STEP_CALL, STEP_END }

signal started() # Dialogue starts up.
signal ended() # Dialogue has ended.
signal ended_w_msg(msg: String) # Dialogue has ended, and includes ending msg.
signal tick() # Step in a stack. May call multiple lines.
signal flow_started(id: String)
signal flow_ended(id: String)
signal option_selected(option: DialogueLine)
signal on_line(text: DialogueLine)
signal _refresh() # called when dialogues were reloaded, and so we should clear the captions/options.

@export var _execute_mode := false # TODO: Implement this differently.
#@export var _break := false # breaking from the flow, temporarilly.
#@export var _active := false # currently in the middle of running?
@export var _stack := [] # current stack of flows, so we can return to a position in a previous flow.
@export var _halting_for := [] # objects that want the flow to _break
@export var _last_tick_stack := [] # stack of the previous tick, used for saving and rollback.

func _init(em := false) -> void:
	_execute_mode = em

func _ready():
	if not Engine.is_editor_hint() and not _execute_mode:
		Saver._get_state.connect(_save_state)
		Saver._set_state.connect(_load_state)
		Saver.pre_load.connect(_game_loaded)
		Global.started.connect(_game_ended)
		Global.ended.connect(_game_started)
		Dialogues.reloaded.connect(_dialogues_reloaded)

func _save_state(state: Dictionary):
	state["DS"] = { stack=_last_tick_stack }

func _load_state(state: Dictionary):
#	_active = state["DS"].active
	_stack = state["DS"].stack

func _dialogues_reloaded():
	_refresh.emit()
	_stack = _last_tick_stack.duplicate(true)
#	_break = false

func _game_loaded():
	end("LOADING")

func _game_started():
	if Dialogues.has_dialogue_flow("MAIN.START"):
		execute("MAIN.START")

func _game_ended():
	end("GAME_ENDED")

func is_halted() -> bool:
	return len(_halting_for) > 0

func halt(halter: Object):
	if not halter in _halting_for:
		_halting_for.append(halter)

func unhalt(halter: Object):
	if halter in _halting_for:
		_halting_for.erase(halter)

#func is_active() -> bool:
#	return _active

func has_steps() -> bool:
	return len(_stack) != 0

func get_current_dialogue() -> Dialogue:
	return null if not len(_stack) else Dialogues.get_dialogue(_stack[-1].did)

func _process(_delta: float) -> void:
	_tick()

func start(id: String):
	if has_steps():
		push_warning("Already started.")
		return
	
	# start dialogue
	if Soot.is_path(id):
		goto(id, STEP_GOTO)
	
	# go to first flow of dialogue
	else:
		var d := Dialogues.get_dialogue(id)
		if not d.has_flows():
			push_error("No flows in '%s'." % id)
		else:
			var first = Dialogues.get_dialogue(id).flows.keys()[0]
			goto(Soot.join_path([id, first]), STEP_GOTO)

func can_do(command: String) -> bool:
	return command.begins_with(Soot.FLOW_GOTO)\
		or command.begins_with(Soot.FLOW_CALL)\
		or command.begins_with(Soot.FLOW_ENDD)

func do(command: String):
	# => goto
	if command.begins_with(Soot.FLOW_GOTO):
		goto(command.trim_prefix(Soot.FLOW_GOTO).strip_edges(), STEP_GOTO)
	# == call
	elif command.begins_with(Soot.FLOW_CALL):
		goto(command.trim_prefix(Soot.FLOW_CALL).strip_edges(), STEP_CALL)
	# <> end
	elif command.begins_with(Soot.FLOW_ENDD):
		end(command.trim_prefix(Soot.FLOW_ENDD).strip_edges())
	else:
		push_error("Don't know what to do with '%s'." % command)

func goto(did_flow: String, step_type: int = STEP_GOTO) -> bool:
	if not Soot.is_path(did_flow):
		push_error("Missing part of goto: '=> %s'." % did_flow)
		return false
	
	var p := Soot.split_path(did_flow)
	var did := p[0]
	var flow := p[1]
	
	if not Dialogues.has_dialogue(did):
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

func end(msg := ""):
	ended.emit()
	ended_w_msg.emit(msg)
	_stack.clear()
	_halting_for.clear()

# select an option, adding it's lines to the stack
func select_option(option: DialogueLine):
	var o := option._data
	if "then" in o:
		_push(option._dialogue_id, "%OPTION%", o.then, STEP_CALL)
	option_selected.emit(option)

func _pop():
	var last: Dictionary = _stack.pop_back()
	if last.type == STEP_GOTO:
		# let everyone know a flow ended
		flow_ended.emit(Soot.join_path([last.did, last.flow]))
	
	if len(_stack) == 0:
		end()

func _push(did: String, flow: String, lines: Array, type: int):
	if len(_stack) == 0:
		started.emit()
	
	_stack.append({ did=did, flow=flow, lines=lines, type=type, step=0 })
	
	if type == STEP_GOTO:
		flow_started.emit(Soot.join_path([did, flow]))

func _tick():
#	if is_halted():
#		return
	
#	if not _active and has_steps():
#		_active = true
#		started.emit()
	
#	if _active and not has_steps():
#		end("END_OF_STEPS")
	
	if has_steps() and not is_halted():
		_last_tick_stack = _stack.duplicate(true)
		tick.emit()
	else:
		return
	
	var safety := MAX_STEPS_PER_TICK
	while has_steps() and not is_halted():
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
				goto(line.line.goto, STEP_GOTO)
				
			"call":
				goto(line.line.call, STEP_CALL)
			
			"end":
				end(line.line.end)
				break
			
			"text":
				if "action" in line.line:
					for a in line.line.action:
						StringAction.do(a)
				
				if not _execute_mode:
					on_line.emit(DialogueLine.new(line.did, line.line))
			
			_:
				push_warning("Huh? %s %s" % [line.line.keys(), line.line])

# forcibly run a flow. usefuly for setting up scenes from a .soot file.
# TODO: do this differently.
func execute(id: String):
	if Dialogues.has_dialogue_flow(id):
		var d = load("res://addons/sooty_engine/autoloads/DialogueStack.gd").new(true)
		d.start(id)
		d._tick()

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
				if StringAction._test(line.conds[i]):
					_push(d.id, flow, line.cond_lines[i], STEP_CALL)
					break
		
		# match chain
		elif line.type == "match":
			var match_result = StringAction._eval(line.match)
			for i in len(line.cases):
				var case = line.cases[i]
				var got = StringAction._eval(case)
				if match_result == got or case == "_":
					_push(did, flow, line.case_lines[i], STEP_CALL)
					break
		
		elif "cond" in line and StringAction._test(line.cond):
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
