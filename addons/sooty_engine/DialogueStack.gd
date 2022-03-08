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
	return null if not len(_stack) else DialogueServer.get_dialogue(_stack[-1].did)

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
		var d := DialogueServer.get_dialogue(id)
		if not d.has_flows():
			push_error("No flows in '%s'." % id)
		else:
			var first = DialogueServer.get_dialogue(id).flows.keys()[0]
			goto("%s.%s" % [id, first])

func goto(flow: String, clear_stack: bool = true, dia_id: Variant = null) -> bool:
	var step := { step=0 }
	var d: Dialogue
	
	if "." in flow:
		var p := flow.split(".", true, 1)
		d = DialogueServer.get_dialogue(p[0])
		flow = p[1]
	
	elif dia_id:
		d = DialogueServer.get_dialogue(dia_id)
		
	elif has_steps():
		d = get_current_dialogue()
	
	else:
		push_error("Call start() before goto().")
		return false
	
	var fid := "%s.%s" % [d.id, flow]
	var lines := DialogueServer.get_flow_lines(fid)
	
	if not len(lines):
		print("Can't find lines for %s" % fid)
		return false
	
	step.did = d.id
	step.lines = lines
	
	if clear_stack:
		_stack.clear()
	
	_stack.append(step)
	return true

# select an option, adding it's lines to the stack
func select_option(option: DialogueLine): # step: Dictionary, option: int):
	var d := get_current_dialogue()
	var o := option._data
	
	if "action" in o:
		StringAction.do(o.action)
	
	if "then_goto" in o:
		_stack.append({did=d.id, lines=o.lines, step=0, goto=o.then_goto})
	else:
		_stack.append({did=d.id, lines=o.lines, step=0})
	
	option_selected.emit(o)

func pop_next_line() -> Dictionary:
	var line := _pop_next_line()
	
	# only show lines that pass a test
	var safety := 100
	while "cond" in line.line:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		# 'if' 'elif' 'else' chain
		if "cond_type" in line.line:
			var do_break := false
			if line.line.cond_type == "if":
				var d := DialogueServer.get_dialogue(line.did)
				for i in len(line.line.tests):
					var test_line := d.get_line(line.line.tests[i])
					if StringAction.test(test_line.cond):
						_stack.append({did=d.id, lines=test_line.lines, step=0})
						do_break = true
						break
				if do_break:
					break
			else:
				push_error("This should never happen.")
		
		if StringAction.test(line.line.cond):
			break
		
		line = _pop_next_line()
	
#	safety = 100
#	while len(line) and "flow" in line.line:
#		safety -= 1
#		if safety <= 0:
#			push_error("Tripped safety.")
#			return {}
#
#		var sl = line.line
#		match sl.flow:
#			"call":
#				goto(sl.call, false)
#				line = _pop_next_line()
#			"goto":
#				if goto(sl.goto):
#					line = _pop_next_line()
	
	return line

func _pop_next_line() -> Dictionary:
	if len(_stack):
		var step: Dictionary = _stack[-1]
		var dia := DialogueServer.get_dialogue(step.did)
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
