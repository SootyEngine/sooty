@tool
extends Node
class_name Flow

const MAX_STEPS_PER_TICK := 20 # Safety limit, in case of excessive loops.
enum { S_GOTO, S_CALL, S_CALL_INLINE, S_PASS, S_OPTION, S_BREAK, S_RETURN, S_IF, S_MATCH, S_LIST }

signal started() # Dialogue starts up.
signal ended() # Dialogue has ended.
signal ended_w_msg(msg: String) # Dialogue has ended, and includes ending msg.
signal passed_w_msg(msg: String) # A 'pass' was called, and included a msg.
signal step_started() # Step in a stack. May call multiple step.
signal flow_started(id: String)
signal flow_ended(id: String)
signal stepped(step: Dictionary)
signal selected(id: String) # used with select_option

@export var flows := {} # flow meta. flows themselves are in _lines.
@export var lines := {} # all lines from all files

@export var last_end_message := ""
@export var current_flow := ""
@export var _broke := false
@export var _started := false
@export var _stack := [] # current stack of flows, so we can return to a position in a previous flow.
@export var _last_tick_stack := [] # stack of the previous tick, used for saving and rollback.
var _sooty: Node

@export var states := {}
@export var last_line := {}
var last_value: Variant

var context: Object = null

func _init(l := {}, f := {}):
	lines = l
	flows = f

func _ready():
	_sooty = get_node("/root/Sooty")

func _get_state() -> Dictionary:
	return {stack=_last_tick_stack, started=_started, last_end_message=last_end_message, states=states}

func _set_state(state: Dictionary):
	_stack = state.stack
	_started = state.started
	last_end_message = state.last_end_message

# ideal way of testing if there is flow.
# _started is false for the first tick, for race condition reasons.
func is_active() -> bool:
	return _started or len(_stack) != 0

func get_current() -> Dictionary:
	return _stack[-1] if len(_stack) else {}

func get_all_flow_ids() -> Array:
	return flows.keys()

func has(path: String) -> bool:
	return path in flows

func has_from_current(path: String) -> bool:
	var flow := evaluate_path(path)
	return flow in lines

func try_start(path: String) -> bool:
	if has(path) and not is_active():
		return start(path)
	else:
		return false
	
func start(id: String):
	if is_active():
		push_warning("Already started.")
		return false
	
	# start dialogue
	current_flow = ""
	last_line = {}
	_goto(id)
	step.call_deferred()
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
		_goto(command.trim_prefix(Soot.FLOW_GOTO).strip_edges())
	# == call
	elif command.begins_with(Soot.FLOW_CALL):
		_add_to_stack(command.trim_prefix(Soot.FLOW_CALL).strip_edges())
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

func _get_line(id: String) -> Dictionary:
	return lines[id]

func _goto(id: String) -> bool:
	return _add_to_stack(id, true)

func _add_to_stack(id: String, clear_stack := false) -> bool:
	var new_id := evaluate_path(id)
	if has(new_id):
		# if the stack is cleared, it means this was a "goto" not a "call"
		if clear_stack:
			while len(_stack):
				_pop()
		var step_type := S_GOTO if clear_stack else S_CALL
		var steps = _get_line(new_id).then
		_push(step_type, new_id, steps)
		return true
	else:
		UString.push_error_similar("No flow '%s' from '%s'." % [new_id, current_flow], id, flows.keys())
		return false

func end(msg := ""):
	if _started:
		last_end_message = msg
		_started = false
		_stack.clear()
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
		current_flow = id
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
	if start(id):
		var safety := 100
		while safety > 0 and is_active():
			step()
			safety -= 1
		return last_value
	else:
		return null

func try_execute(path: String) -> Variant:
	if has(path):
		return execute(path)
	else:
		return null

func break_step(msg := ""):
	_broke = true

func step():
	_broke = false
	if _started:
		# is start of tick?
		if len(_stack):# and not _broke:
			_last_tick_stack = _stack.duplicate(true)
			step_started.emit()
		# has finished?
		else:
			end()
	
	var safety := MAX_STEPS_PER_TICK
	while _started and len(_stack) and not _broke:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety! Increase MAX_STEPS_PER_TICK if necessary.", safety)
			break
		
		var next_line := _pop_stack_line()
		if next_line:
			last_line = next_line
			last_value = null
			
			var line := next_line
			_on_step(line)
			stepped.emit(line)
			
			match line.type:
				"goto":
					_goto(line.goto)
				
				"call":
					# does call have it's own lines? used by {[list]} pattern
					if "then" in line:
						_push(S_CALL_INLINE, line.M.id, line.then)
					# use current_dialogue as parent, if none exists
					_add_to_stack(line.call)
				
				"do":
					last_value = _sooty.actions.do(line.do, context)
				
				"text":
					last_value = line.text
				
				"pass":
					passed_w_msg.emit(line.msg)
					last_value = line.msg
					pass
				
				"end":
					_pop()
				
				"end_all":
					end(line.end_all)
					last_value = line.end_all
					break
				
				_:
					push_warning("Huh? %s %s" % [line.keys(), line])
	
	# emit start trigger
	if not _started and len(_stack):
		_started = true
		started.emit()

func _pop_stack_line() -> Dictionary:
	# only show lines that pass their {{condition}}.
	var safety := 1000
	while len(_stack):
		safety -= 1
		if safety <= 0:
			push_error("Popped safety.")
			break
		
		# remove last step, and potentially end the flow.
		var step_info: Dictionary = _stack[-1]
		if not len(step_info.steps):
			_pop()
			continue
		
		var step_id: String = step_info.steps.pop_front()
		var line: Dictionary = _get_line(step_id)
		
		# 'if' 'elif' 'else' chain
		if line.type == "if":
			for i in len(line.conds):
				if _sooty.actions.test(line.conds[i], context):
					_push(S_IF, line.M.id, line.cond_lines[i])
					return {}
		
		# match chain
		elif line.type == "match":
			var match_result = Array(line.match.split(" JOIN "))
			for i in len(match_result):
				var m = match_result[i]
				match_result[i] = _sooty.actions.do(m, context)
			# not an array?
			if len(match_result) == 1:
				match_result = match_result[0]
			# TODO: if an array of objects, merge them into a super object!?
			
#			print("MATCH: ", match_result)
			for i in len(line.cases):
				var case = line.cases[i].split(" OR ")
				for subcase in case:
					subcase = Array(subcase.split(" JOIN "))
					for i in len(subcase):
						var sc = subcase[i]
						# by default, treat it as an array of strings seperated by spaces
						if not sc[0] in "~$@":
							sc = "*" + sc
						subcase[i] = _sooty.actions.do(sc, context)
					var passes = _compare_list(match_result, subcase)
#					print("\tCASE: %s == %s? %s!" % [subcase, match_result, passes])
					if passes:
#						print("\t\tGOOD!")
						_push(S_MATCH, line.M.id, line.case_lines[i])
						return {}
		
		# has a condition
		elif "cond" in line:
			if _sooty.actions.test(line.cond, context):
				return line
		
		# special list function
		elif line.type == "list":
			var id: String = line.M.id
			var list: Array = line.list
			var lstep_id := get_list_item(id, line.list_type, list)
			if lstep_id:
				_push(S_LIST, line.M.id, [lstep_id])
			return {}
		
		else:
			return line
	
	return {}

func _compare_list(m, v) -> bool:
	for i in len(v):
		if _compare(m, v[i]):
			return true
	return false
	
func _compare(match_val: Variant, case_val: Variant) -> bool:
	var match_type := typeof(match_val)
	var case_type := typeof(case_val)
	
	# is autopass?
	if UType.same_type_and_value(case_val, "_"):
		return true
	
	# all elements or dict/list are the same?
	elif match_type in [TYPE_DICTIONARY, TYPE_OBJECT] and case_type == TYPE_DICTIONARY:
		for property in case_val:
			# default/ignore argument
			if UType.same_type_and_value(case_val[property], "_"):
				continue
			# no property, or aren't equal?
			if not property in match_val or not UType.same_type_and_value(case_val[property], match_val[property]):
				return false
		return true
	
	# both are same type?
	elif match_type == case_type:
		return match_val == case_val
	
	else:
		return false

func _replace_list_text(text: String, id: String) -> String:
	var parts := Array(text.split("|")).map(func(x: String): return x.strip_edges())
	var type = parts.pop_front()
	return get_list_item(id, type, parts)

# for strings with "{list_type|item|item|item}" pattern
# this selects an item based on the list_type
func replace_list_text(id: String, text: String) -> String:
	return UString.replace_between(text, "<", ">", _replace_list_text.bind(id))

func reset_list(id: String):
	states.erase(id)

const LIST_TYPES := {
	"": "Default: Go through steps, then loop around.",
	"rand": "Random: Pick a random step.",
	"stop": "Stop: Go through steps, then stop at last one.",
	"hide": "Hide: Go through steps, then hide."
}

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
		
		_:
			push_error("Unknown list type '%s'." % type)
	
	return ""

static func line_has_options(line: Dictionary) -> bool:
	return "options" in line

static func line_has_condition(line: Dictionary) -> bool:
	return "cond" in line

func line_passes_condition(line: Dictionary) -> bool:
	return _sooty.actions.test(line.cond, context)

func line_get_options(line: Dictionary) -> Array:
	var out_lines := []
	if line_has_options(line):
		_get_options(line.options, out_lines, 0)
	return out_lines

# works like a file path system
# or the Godot NodePath system
# `node` goes to child
# `node/node2` goes to a grandchild
# `.node` goes to a sibling
# `..node` goes to a parent sibling
# `/node` goes to a root flow
func evaluate_path(next: String) -> String:
	return _evaluate_path(current_flow, next)

static func _evaluate_path(from: String, was: String) -> String:
	var next := was
	if next:
		# going to a root
		if next.begins_with("/"):
			return next.substr(1)
		else:
			var path := from
			while next.begins_with("."):
				next = next.substr(1)
				if "/" in path:
					path = path.rsplit("/", true, 1)[0]
				else:
					path = ""
			
			if next:
				if path:
					return path.plus_file(next)
				else:
					return next
			else:
				return path
	else:
		return from

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

func generate_tree() -> Dictionary:
	var out := {}
	for p in flows:
		UDict.set_at(out, p.split("/"), {})
	return out

func get_flow_children(path: String) -> Array:
	var tree := generate_tree()
	if path:
		var got = UDict.get_at(tree, path.split("/"))
		return got.keys() if got else []
	else:
		return tree.keys()

# flow path based on scene name
# so passing "_init" while in "res://my_scene.tres" gets "my_scene/_init" 
static func get_scene_path(path: String) -> String:
	var scene_id := UFile.get_file_name(Global.get_tree().current_scene.scene_file_path)
	return scene_id.plus_file(path)
