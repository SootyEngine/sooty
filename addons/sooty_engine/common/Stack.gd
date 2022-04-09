extends Node
class_name SootStack

const MAX_STEPS_PER_TICK := 20 # Safety limit, in case of excessive loops.
enum { S_GOTO, S_CALL, S_PASS, S_OPTION, S_BREAK, S_RETURN, S_IF, S_MATCH }

signal started() # Dialogue starts up.
signal ended() # Dialogue has ended.
signal ended_w_msg(msg: String) # Dialogue has ended, and includes ending msg.
signal passed_w_msg(msg: String) # A 'pass' was called, and included a msg.
signal tick() # Step in a stack. May call multiple lines.
signal flow_started(id: String)
signal flow_ended(id: String)
signal on_step(step: Dictionary)
signal selected(id: String) # used with select_option
signal waiting_list_changed()

@export var last_end_message := ""
@export var _started := false
@export var _stack := [] # current stack of flows, so we can return to a position in a previous flow.
@export var _waiting_for := [] # objects that want the flow to _break
@export var _last_tick_stack := [] # stack of the previous tick, used for saving and rollback.

func _get_state() -> Dictionary:
	return {stack=_last_tick_stack, started=_started, last_end_message=last_end_message}

func _set_state(state: Dictionary):
	_stack = state.stack
	_started = state.started
	last_end_message = state.last_end_message

func is_waiting() -> bool:
	return len(_waiting_for) > 0

func wait(waiter: Object):
	if not waiter in _waiting_for:
		_waiting_for.append(waiter)
		waiting_list_changed.emit()

func unwait(waiter: Object):
	if waiter in _waiting_for:
		_waiting_for.erase(waiter)
		waiting_list_changed.emit()

func clear_waiting_list():
	_waiting_for.clear()
	waiting_list_changed.emit()

func is_active() -> bool:
	return len(_stack) != 0

func get_current() -> Dictionary:
	return _stack[-1] if len(_stack) else {}

func start(id: String):
	if is_active():
		push_warning("Already started.")
		return
	
	# start dialogue
	goto(id)

func can_do(command: String) -> bool:
	return command.begins_with(Soot.FLOW_GOTO)\
		or command.begins_with(Soot.FLOW_CALL)\
		or command.begins_with(Soot.FLOW_PASS)\
		or command.begins_with(Soot.FLOW_ENDD)\
		or command.begins_with(Soot.FLOW_END_ALL)

func do(command: String):
	# => goto
	if command.begins_with(Soot.FLOW_GOTO):
		_goto(command.trim_prefix(Soot.FLOW_GOTO).strip_edges(), S_GOTO)
	# == call
	elif command.begins_with(Soot.FLOW_CALL):
		_goto(command.trim_prefix(Soot.FLOW_CALL).strip_edges(), S_CALL)
	# __ pass
	elif command.begins_with(Soot.FLOW_PASS):
		# do nothing
		pass
	# >< end flow
	elif command.begins_with(Soot.FLOW_ENDD):
		_pop()
	# >><< end dialogue
	elif command.begins_with(Soot.FLOW_END_ALL):
		end(command.trim_prefix(Soot.FLOW_END_ALL).strip_edges())
	else:
		push_error("Don't know what to do with '%s'." % command)

func stack(id: String) -> bool:
	return _goto(id, S_CALL)

func goto(id: String) -> bool:
	return _goto(id, S_GOTO)

func _has_step(id: String) -> bool:
	assert(false)
	return false

func _get_step(id: String) -> Dictionary:
	assert(false)
	return {}

func _goto(id: String, step_type: int = S_GOTO) -> bool:
	if _has_step(id):
		# if the stack is cleared, it means this was a "goto" not a "call"
		if step_type == S_GOTO:
			while len(_stack):
				_pop()
		
		_push(step_type, id)
		return true
	else:
		push_error("No step %s." % id)
		return false

func end(msg := ""):
	if _started:
		last_end_message = msg
		_started = false
		_stack.clear()
		clear_waiting_list()
		ended.emit()
		ended_w_msg.emit(msg)

# select an option, adding it's lines to the stack
func select_option(id: String):
	var option := _get_step(id)
	if "then" in option:
		_push(S_OPTION, id)
	selected.emit(id)

func _pop():
	var last: Dictionary = _stack.pop_back()
	# a flow ended
	if last.type in [S_GOTO, S_CALL]:
		_flow_ended(last.id)

func _push(type: int, id: String, key: String="then"):
	_stack.append({ type=type, id=id, key=key, step=0 })
	print(_stack)
	
	# a flow started
	if type in [S_GOTO, S_CALL]:
		_flow_started.call_deferred(id)

func _flow_started(id: String):
	flow_started.emit(id)

func _flow_ended(id: String):
	flow_ended.emit(id)

func _on_step(step: Dictionary):
	pass

func _tick():
	if _started:
		# has finished?
		if not len(_stack):
			end()
		
		# is start of tick?
		if len(_stack) and not is_waiting():
			_last_tick_stack = _stack.duplicate(true)
			tick.emit()
	
	var safety := MAX_STEPS_PER_TICK
	while _started and len(_stack) and not is_waiting():
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety! Increase MAX_STEPS_PER_TICK if necessary.", safety)
			break
		
		var step := _pop_next_step()
		print("STEP ", step)
		
		if step:
			_on_step(step)
			on_step.emit(step)
			
			match step.type:
				"goto": _goto(step.goto, S_GOTO)
				"call": _goto(step.call, S_CALL)
				"action", "flag", "prop": pass
#				"action": on_action.emit(step.action)
#				"flag": on_flag.emit(step.flag)
#				"prop": on_property.emit(step.prop, step.value)
				
				"pass":
					passed_w_msg.emit(step.msg)
					pass
				
				"end": _pop()
				"end_all":
					end(step.end)
					break
				
				"array":
					match step.array_type:
						_: print("GOT ARRAY ", step)
				
				_: push_warning("Huh? %s %s" % [step.keys(), step])
	
	# emit start trigger
	if not _started and len(_stack):
		_started = true
		started.emit()

func _pop_next_step() -> Dictionary:
	# only show lines that pass their {{condition}}.
	var safety := 1000
	while len(_stack):
		safety -= 1
		if safety <= 0:
			push_error("Popped safety.")
			break
		
		# remove last step, and potentially end the flow.
		var step_info: Dictionary = _stack[-1]
		var steps: Array = _get_step(step_info.id).get(step_info.key, "then")
		if step_info.step >= len(steps):
			_pop()
			continue
		
		var step: Dictionary = _get_step(steps[step_info.step]) 
		step_info.step += 1
#		var dilg: Dialogue = Dialogues.get_dialogue(step_info.d_id)
#		var line: Dictionary = dilg.get_line(lines[step_info.step])
#		var d_id: String = step_info.d_id
#		var flow: String = step_info.flow
		
#		var out := {d_id=d_id, flow=flow, line=line}
		
		# 'if' 'elif' 'else' chain
		if step.type == "if":
			for i in len(step.conds):
				if StringAction._test(step.conds[i]):
					_push(S_IF, "cond_lines_%s" % i)
					return {}
		
		# match chain
		elif step.type == "match":
			var match_result = State._eval(step.match)
			for i in len(step.cases):
				var case = step.cases[i]
				if case == "_" or UType.is_equal(match_result, State._eval(case)):
					_push(S_MATCH, "case_lines_%s" % i)
					return {}
		
		# has a condition
		elif "cond" in step:
			if StringAction._test(step.cond):
				return step
		
		else:
			return step
	
	return {}
