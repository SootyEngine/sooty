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
		
		if "action" in line.line:
			on_action.emit(line.line.action)
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

func goto(flow: String, clear_stack: bool = true):
	var step := { step=0 }
	
	if "." in flow:
		var p := flow.split(".", true, 1)
		var d := DialogueServer.get_dialogue(p[0])
		step.did=d.id
		step.lines=d.get_flow(p[1]).lines
	
	elif has_steps():
		var d := get_current_dialogue()
		step.did=d.id
		step.lines=d.get_flow(flow).lines
	
	else:
		push_error("Call start() before goto().")
		return
	
	if clear_stack:
		_stack.clear()
	
	_stack.append(step)



# Used for options.
#func select() -> bool:
#	if _parent and _stack and "lines" in _data:
#		_stack.select_option(_parent._data, _index)
#		return true
#	push_error("Line is not an Option.")
#	return false

# select an option, adding it's lines to the stack
func select_option(option: DialogueLine): # step: Dictionary, option: int):
	var d := get_current_dialogue()
	print("OPTION ", option)
	print("PARENT ", option.parent)
	var o := d.get_line(option.parent._data.options[option.option_index])
	if "then_goto" in o:
		_stack.append({did=d.id, lines=o.lines, step=0, goto=o.then_goto})
	else:
		_stack.append({did=d.id, lines=o.lines, step=0})
	
	option_selected.emit(o)

func pop_next_line() -> Dictionary:
	var line := _pop_next_line()
	
	# only show lines that pass a test
	var safety := 100
	while "condition" in line.line:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		if StringAction.test(line.line.condition):
			break
		
		line = _pop_next_line()
	
	safety = 100
	while "call" in line.line or "goto" in line.line:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		if "call" in line.line:
			goto(line.line.call, false)
			line = _pop_next_line()
		else:
			goto(line.goto)
			line = _pop_next_line()
	
	return line

func _pop_next_line() -> Dictionary:
	if len(_stack):
		var step: Dictionary = _stack[-1]
		var line: Dictionary = DialogueServer.get_dialogue(step.did).get_line(step.lines[step.step])
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
