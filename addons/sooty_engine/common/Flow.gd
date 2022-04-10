@tool
extends Waiter
class_name Flow

const MAX_STEPS_PER_TICK := 20 # Safety limit, in case of excessive loops.
enum { S_GOTO, S_CALL, S_CALL_INLINE, S_PASS, S_OPTION, S_BREAK, S_RETURN, S_IF, S_MATCH, S_LIST }

signal started() # Dialogue starts up.
signal ended() # Dialogue has ended.
signal ended_w_msg(msg: String) # Dialogue has ended, and includes ending msg.
signal passed_w_msg(msg: String) # A 'pass' was called, and included a msg.
signal tick() # Step in a stack. May call multiple lines.
signal flow_started(id: String)
signal flow_ended(id: String)
signal on_step(step: Dictionary)
signal selected(id: String) # used with select_option

var _lines := {} # all lines from all files

@export var last_end_message := ""
@export var current_dialogue := ""
@export var _started := false
@export var _stack := [] # current stack of flows, so we can return to a position in a previous flow.
@export var _last_tick_stack := [] # stack of the previous tick, used for saving and rollback.

@export var states := {}

func _get_state() -> Dictionary:
	return {stack=_last_tick_stack, started=_started, last_end_message=last_end_message, states=states}

func _set_state(state: Dictionary):
	_stack = state.stack
	_started = state.started
	last_end_message = state.last_end_message

func is_active() -> bool:
	return len(_stack) != 0

func get_current() -> Dictionary:
	return _stack[-1] if len(_stack) else {}

func start(id: String):
	if is_active():
		push_warning("Already started.")
		return false
	
	# start dialogue
	goto(id)
	return true

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

func _has_line(id: String) -> bool:
	return id in _lines

func _get_line(id: String) -> Dictionary:
	return _lines[id]

func _goto(id: String, step_type: int = S_GOTO) -> bool:
	if _has_line(id):
		# if the stack is cleared, it means this was a "goto" not a "call"
		if step_type == S_GOTO:
			while len(_stack):
				_pop()
		
		_push(step_type, id, _get_line(id).then)
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
	var option := _get_line(id)
	if "then" in option:
		_push(S_OPTION, id, option.then)
	selected.emit(id)

func _pop():
	var last: Dictionary = _stack.pop_back()
	# a flow ended
	if last.type in [S_GOTO, S_CALL]:
		_flow_ended(last.id)

func _push(type: int, id: String, list: Array):# key: String="then"):
	_stack.append({ type=type, id=id, steps=list.duplicate() })# id=id, key=key, step=0 })
	
	# a flow started
	if type in [S_GOTO, S_CALL]:
		current_dialogue = Soot.split_path(id)[0]
		_flow_started.call_deferred(id)

func _flow_started(id: String):
	flow_started.emit(id)

func _flow_ended(id: String):
	flow_ended.emit(id)

func _on_step(step: Dictionary):
	pass

# run through the flow and return the last line
# to_value will attempt to convert it from a line to something else
func execute(id: String) -> Variant:
	var out := { line={}, value=null }
	if start(id):
		var safety := 100
		while safety > 0 and is_active():
			out.line = _tick()
			safety -= 1
		match out.line.get("type"):
			"action": out.value = StringAction.do(out.line.action)
	return out

func _tick() -> Dictionary:
	if _started:
		# has finished?
		if not len(_stack):
			end()
		
		# is start of tick?
		if len(_stack) and not is_waiting():
			_last_tick_stack = _stack.duplicate(true)
			tick.emit()
	
	var safety := MAX_STEPS_PER_TICK
	var step := {}
	while _started and len(_stack) and not is_waiting():
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety! Increase MAX_STEPS_PER_TICK if necessary.", safety)
			break
		
		var next_step := _pop_next_step()
		if next_step:
			step = next_step
			_on_step(step)
			on_step.emit(step)
			
			match step.type:
				"goto":
					var goto = step.goto
					if not Soot.is_path(goto):
						goto = Soot.join_path([current_dialogue, goto])
					_goto(goto, S_GOTO)
				
				"call":
					# does call have it's own lines? used by {[list]} pattern
					if "then" in step:
						_push(S_CALL_INLINE, step.M.id, step.then)
					# use current_dialogue as parent, if none exists
					var call = step.call
					if not Soot.is_path(call):
						call = Soot.join_path([current_dialogue, call])
					_goto(call, S_CALL)
				
				"action", "text":
					pass
				
				"pass":
					passed_w_msg.emit(step.msg)
					pass
				
				"end":
					_pop()
				
				"end_all":
					end(step.end)
					break
				
				_: push_warning("Huh? %s %s" % [step.keys(), step])
	
	# emit start trigger
	if not _started and len(_stack):
		_started = true
		started.emit()
	
	return step

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
		# _get_step(step_info.id).get(step_info.key, "then")
		if not len(step_info.steps):#.step:# >= len(steps):
			_pop()
			continue
		
		var step: Dictionary = _get_line(step_info.steps.pop_front())
#		step_info.step += 1
		
		# 'if' 'elif' 'else' chain
		if step.type == "if":
			for i in len(step.conds):
				if StringAction._test(step.conds[i]):
					_push(S_IF, step.M.id, step.cond_lines[i])
					return {}
		
		# match chain
		elif step.type == "match":
			var match_result = State._eval(step.match)
			for i in len(step.cases):
				var case = step.cases[i]
				if case == "_" or UType.is_equal(match_result, State._eval(case)):
					_push(S_MATCH, step.M.id, step.case_lines[i])
					return {}
		
		# has a condition
		elif "cond" in step:
			if StringAction._test(step.cond):
				return step
		
		# special list function
		elif step.type == "list":
			var id: String = step.M.id
			var list: Array = step.list
			var lstep_id := get_list_item(step.list_type, id, list)
			if lstep_id:
				_push(S_LIST, step.M.id, [lstep_id])
			return {}
		
		else:
			return step
	
	return {}

func _replace_text_lists(text: String, id: String) -> String:
	var parts := Array(text.split("|")).map(func(x: String): return x.strip_edges())
	var type = parts.pop_front()
	return get_list_item(id, type, parts)

# for strings with "{list_type|item|item|item}" pattern
# this selects an item based on the list_type
func replace_list_text(id: String, text: String) -> String:
	return UString.replace_between(text, "{", "}", _replace_text_lists.bind(id))

func reset_list(id: String):
	states.erase(id)

# return an item from a list, and changes the lists state for next time
func get_list_item(id: String, type: String, list: Array) -> String:
	var tot := len(list)
	match type:
		# just go through all steps, then loop around
		"":
			if not id in states:
				states[id] = 0
			else:
				states[id] = wrapi(states[id] + 1, 0, tot)
			return list[states[id]]
		
		# pick a random step. never the same one twice.
		"rand":
			if not id in states:
				states[id] = randi() % tot
			elif tot > 1:
				while true:
					var next := randi() % tot
					if next != states[id]:
						states[id] = next
						break
			return list[states[id]]
		
		# stop at last element.
		"stop":
			if not id in states:
				states[id] = 0
			elif states[id] < tot-1:
				states[id] += 1
			return list[states[id]]
		
		# hide when finished.
		"hide":
			if not id in states:
				states[id] = 0
			elif states[id] < tot:
				states[id] += 1
			if states[id] < tot:
				return list[states[id]]
	
	return ""

func line_has_options(line: Dictionary) -> bool:
	return "options" in line

func line_has_condition(line: Dictionary) -> bool:
	return "cond" in line

func line_passes_condition(line: Dictionary) -> bool:
	return StringAction._test(line.cond)

func line_get_options(line: Dictionary) -> Array:
	var out_lines := []
	if line_has_options(line):
		_get_options(line.options, out_lines, 0)
	return out_lines

func _get_options(ids: Array, output: Array, depth: int):
	if depth > 4:
		push_error("Possible loop!?")
		return
	
	for i in len(ids):
		var line: Dictionary = _get_line(ids[i])
		var passed := not line_has_condition(line) or line_passes_condition(line)
		match line.get("flag", ""):
			"++":
				# recursively collect options from other flows
				if passed:
					var flow_id: String = line.text
					var flow_step_ids: Array = _get_line(flow_id).then
					_get_options(flow_step_ids, output, depth+1)
			_:
				output.append({id=ids[i], line=line, passed=passed})
#		if "flow" in opdata:
#			if opdata.flow == "call":
#				var fid: String = opdata.call
#				var flines := Dialogues.get_flow_lines(fid)
#				_get_options(flines, output, only_passing, depth+1)
#		else:
#			if only_passing and "cond" in opdata and not StringAction.test(opdata.cond):
#				continue
#
#			out.append(DialogueLine.new(_dialogue_id, opdata))
