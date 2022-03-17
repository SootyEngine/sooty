@tool
extends Resource
class_name DialogueStack


signal started()
signal finished()
signal tick_started()
signal tick_finished()
signal option_selected(option: Dictionary)
signal on_line(text: DialogueLine)

@export var wait := false
@export var _started := false
@export var _stack := []
@export var _history := []

func has_steps() -> bool:
	return len(_stack) != 0

func get_current_dialogue() -> Dialogue:
	return null if not len(_stack) else Dialogues.get_dialogue(_stack[-1].did)

func tick():
	if wait:
		return
	
	if not _started and has_steps():
		_started = true
		started.emit()
	
	if _started and not has_steps():
		_started = false
		finished.emit()
		_history.clear()
	
	if has_steps() and not wait:
		tick_started.emit()
	else:
		return
	
	var safety := 100
	while has_steps() and not wait:
		safety -= 1
		if safety <= 0:
			print("Tripped safety!", safety)
			break
		
		var line := pop_next_line()
		print(line)
		
		if not len(line):
			break
		
		match line.line.type:
			"action":
				var act: String = line.line.action
				if act.begins_with(Sooty.S_ACTION_EVAL):
					act = act.substr(1).strip_edges()
					State._eval(act)
				elif act.begins_with(Sooty.S_ACTION_SHORTCUT):
					act = act.substr(1).strip_edges()
					State._eval(Sooty.process_shortcut(act))
					
			"goto": goto(line.line.goto, true)
			"call": goto(line.line.call, false)
			"text": on_line.emit(DialogueLine.new(line.did, line.line))
			_: print("Huh? ", line.line.keys(), line.line)
	
	tick_finished.emit()
	
func start(id: String):
	if _started:
		push_warning("Already started.")
		return
	
	# start dialogue
	if "." in id:
		goto(id)
	
	# go to first flow of dialogue
	else:
		var d := Dialogues.get_dialogue(id)
		if not d.has_flows():
			push_error("No flows in '%s'." % id)
		else:
			var first = Dialogues.get_dialogue(id).flows.keys()[0]
			goto("%s.%s" % [id, first])

func goto(did_flow: String, clear_stack: bool = true) -> bool:
	var p := did_flow.split(".", true, 1)
	var did: String = p[0]
	var flow: String = p[1]
	
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
	
	if clear_stack:
		_stack.clear()
		_history.append("%s.%s" % [did, flow])
	
	_push(did, lines)
	return true

# select an option, adding it's lines to the stack
func select_option(option: DialogueLine):
	var o := option._data
	if "then" in o:
		_push(option._dialogue_id, o.then)
	option_selected.emit(o)

func _push(did: String, lines: Array, extra := {}):
	var step := { did=did, lines=lines, step=0 }
	for k in extra:
		step[k] = extra[k]
	_stack.append(step)

func pop_next_line() -> Dictionary:
	var did_line := _pop_next_line()
	var did: String = did_line.did
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
					_push(d.id, line.cond_lines[i])
					break
		
		# match chain
		elif line.type == "match":
			var match_result = State._eval(line.match)
			for i in len(line.cases):
				var case = line.cases[i]
				var got = State._eval(case)
#				print("\tCASE %s: '%s' -> %s == %s (%s)" % [i, line.cases[i], got, match_result, match_result == got])
				if match_result == got or case == "_":
					_push(did, line.case_lines[i])
					break
		
		elif "cond" in line and State._test(line.cond):
			break
		
		did_line = _pop_next_line()
		did = did_line.did
		line = did_line.line
	
	return did_line

func _pop_next_line() -> Dictionary:
	if len(_stack):
		var step: Dictionary = _stack[-1]
		
		if not len(step.lines):
			push_error("Shouldn't happen.")
			_stack.pop_back()
			return {}
		
		var dilg := Dialogues.get_dialogue(step.did)
		var line: Dictionary = dilg.get_line(step.lines[step.step])
		var out := { did=step.did, line=line }
		
		step.step += 1
		
		if step.step >= len(step.lines):
			_stack.pop_back()
		
		return out
	
	else:
		push_error("Dialogue stack is empty.")
		return {}
