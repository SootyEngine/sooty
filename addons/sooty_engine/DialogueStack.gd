@tool
extends Resource
class_name DialogueStack

signal started()
signal finished()
signal tick_started()
signal tick_finished()
signal option_selected(option: Dictionary)
signal on_action(action: String)
signal on_line(text: DialogueLine)

@export var wait := false
@export var _started := false
@export var _stack := []

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
	
	var safety := 100
	if has_steps() and not wait:
		tick_started.emit()
	else:
		return
	
	while has_steps() and not wait:
		safety -= 1
		if safety <= 0:
			print("Tripped safety!", safety)
			break
		
		var line := pop_next_line()
		
		if not len(line):
			break
		
		if "action" in line.line:
			on_action.emit(line.line.action)
		elif "goto" in line.line:
			goto(line.line.goto, true, line.did)
		elif "call" in line.line:
			goto(line.line.call, false, line.did)
		elif "text" in line.line:
			on_line.emit(DialogueLine.new(line.did, line.line))
		else:
			print("Huh? ", line)
	
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

func goto(flow: String, clear_stack: bool = true, dia_id: Variant = null) -> bool:
	var d: Dialogue
	
	if "." in flow:
		var p := flow.split(".", true, 1)
		d = Dialogues.get_dialogue(p[0])
		flow = p[1]
	
	elif dia_id:
		d = Dialogues.get_dialogue(dia_id)
		
	elif has_steps():
		d = get_current_dialogue()
	
	else:
		push_error("Call start() before goto().")
		return false
	
	var fid := "%s.%s" % [d.id, flow]
	var lines := Dialogues.get_flow_lines(fid)
	
	if not len(lines):
		print("Can't find lines for %s" % fid)
		return false
	
	if clear_stack:
		_stack.clear()
	
	_push(d.id, lines)
	return true

# select an option, adding it's lines to the stack
func select_option(option: DialogueLine): # step: Dictionary, option: int):
	var d := get_current_dialogue()
	var o := option._data
	
	if "action" in o:
		StringAction.do(o.action)
	
	if "then_goto" in o:
		_push(d.id, o.lines, {goto=o.then_goto})
	else:
		_push(d.id, o.lines)
	
	option_selected.emit(o)

func _push(did: String, lines: Array, extra := {}):
	var step := { did=did, lines=lines, step=0 }
	for k in extra:
		step[k] = extra[k]
	_stack.append(step)

func pop_next_line() -> Dictionary:
	var line := _pop_next_line()
	
	# only show lines that pass a test
	var safety := 100
	while len(line) and "cond" in line.line:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		prints("<>", line.keys())
		if "cond_type" in line.line:
			# 'if' 'elif' 'else' chain
			if line.line.cond_type == "if":
				var d := Dialogues.get_dialogue(line.did)
				for i in len(line.line.tests):
					var test_line := d.get_line(line.line.tests[i])
					if StringAction.test(test_line.cond):
						_push(d.id, test_line.lines)
						break
			
			# match chain
			elif line.line.cond_type == "match":
				var match_result = StringAction.str_to_var(line.line.cond)
				for i in len(line.line.cases):
					if match_result == StringAction.str_to_var(line.line.cases[i]):
						var d := Dialogues.get_dialogue(line.did)
						_push(d.id, line.line.case_lines[i])
						break
				
			else:
				push_error("This should never happen.")
			
		elif StringAction.test(line.line.cond):
			break
		
		line = _pop_next_line()
	
	return line

func _pop_next_line() -> Dictionary:
	if len(_stack):
		var step: Dictionary = _stack[-1]
		var dia := Dialogues.get_dialogue(step.did)
		var line: Dictionary = dia.get_line(step.lines[step.step])
		var out := { did=step.did, line=line }
		
		step.step += 1
		
		if step.step >= len(step.lines):
			_stack.pop_back()
			
			if "goto" in step:
				goto(step.goto)
		
		return out
	
	else:
		push_error("Dialogue stack is empty.")
		return {}
