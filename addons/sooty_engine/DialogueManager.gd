@tool
extends Node
class_name DialogueManager

const OPERATOR_ASSIGN := ["=", "+=", "-="]

var cache := {}
var stack := []
var state := State

func _get_tool_buttons():
	return [do_test]

func do_test():
	var action := 'dummy1.act "String test okay?" $score'
	print(do_action(action))
#	print("tee hee", get_tree().get_first_node_in_group("dummy1"))

func is_active() -> bool:
	return len(stack) != 0

func get_current_dialogue() -> Dialogue:
	return null if not len(stack) else get_dialogue(stack[-1].did)

func get_dialogue(id: String) -> Dialogue:
	if not id in cache:
		var d := Dialogue.new(id)
		if d.has_errors():
			push_error("Bad dialogue: %s.")
			return null
		else:
			add_dialogue(id, d)
			return d
	else:
		return cache[id]

func add_dialogue(id: String, d: Dialogue):
	d.id = id
	cache[id] = d

func start(id: String):
	# start dialogue
	if "." in id:
		goto(id)
	
	# go to first flow of dialogue
	else:
		var d := get_dialogue(id)
		if not d.has_flows():
			push_error("No flows in '%s'." % id)
		else:
			var first = get_dialogue(id).flows.keys()[0]
			goto("%s.%s" % [id, first])

func goto(flow: String, clear_stack: bool = true):
	var step := { step=0 }
	
	if "." in flow:
		var p := flow.split(".", true, 1)
		var d := get_dialogue(p[0])
		step.did=d.id
		step.lines=d.get_flow(p[1]).lines
	
	elif is_active():
		var d := get_current_dialogue()
		step.did=d.id
		step.lines=d.get_flow(flow).lines
	
	else:
		push_error("Call start() before goto().")
		return
	
	if clear_stack:
		stack.clear()
	
	stack.append(step)

# collect all options that pass their conditions
func get_options(step: Dictionary) -> Array:
	var out := []
	var d := get_current_dialogue()
	for l in step.options:
		var op := d.get_line(l)
		if "condition" in op and test_condition(op.condition):
			out.append(op)
	return out

# select an option, adding it's lines to the stack
func select_option(step: Dictionary, option: int):
	var d := get_current_dialogue()
	var o := d.get_line(step.options[option])
	if "then_goto" in o:
		stack.append({did=d.id, lines=o.lines, step=0, goto=o.then_goto})
	else:
		stack.append({did=d.id, lines=o.lines, step=0})

func get_next_line() -> Dictionary:
	var line := _get_next_line()
	
	# only show lines that pass a test
	var safety := 100
	while "condition" in line:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		if test_condition(line.condition):
			break
		
		line = _get_next_line()
	
	safety = 100
	while "call" in line or "goto" in line:
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			return {}
		
		if "call" in line:
			goto(line.call, false)
			line = _get_next_line()
		else:
			goto(line.goto)
			line = _get_next_line()
	
	return line

func _get_next_line() -> Dictionary:
	if len(stack):
		var step: Dictionary = stack[-1]
		var line: Dictionary = get_dialogue(step.did).get_line(step.lines[step.step])
		
		step.step += 1
		
		if step.step >= len(step.lines):
			stack.pop_back()
			
			if "goto" in step:
				goto(step.goto)
		
		return line
	
	else:
		push_error("Dialogue stack is empty.")
		return {}

func test_condition(condition: String) -> bool:
	var result = execute_expression(condition, false)
	prints("tested '%s' got '%s'" % [condition, result])
	return true if result else false

func execute_expression(e: String, default=null, d: Dictionary={}):
	var expression := Expression.new()
	if expression.parse(e, PackedStringArray(d.keys())) == OK:
		var result = expression.execute(d.values(), state, false)
		if expression.has_execute_failed():
			push_error(e)
		return result
	return default

func do_action(s: String):
	var parts := _split_string(s)
	print(parts)
	
	# assignment
	if len(parts) == 1:
		if s.ends_with("++"):
			var action := "%s += 1" % s.trim_suffix("++")
			return execute_expression(action)
			
		elif s.ends_with("--"):
			var action := "%s -= 1" % s.trim_suffix("--")
			return execute_expression(action)
	
	# assignment
	if len(parts) == 3 and parts[1] in OPERATOR_ASSIGN:
		return execute_expression(s)
	
	# function
	var args := []
	var fname: String = parts.pop_front()
	var target: Node = get_tree().current_scene
	
	if "." in fname:
		var p := fname.split(".")
		fname = p[1]
		target = get_tree().get_first_node_in_group(p[0])
	
		if not target:
			push_error("Can't find node '%s'." % p[0])
			return
		
	for p in parts:
		if ":" in p:
			var kv = p.split(":", true, 1)
			if not len(args) or not args[-1] is Dictionary:
				args.append({})
			args[-1][kv[0]] = _str_to_varstr(kv[1])
		
		else:
			args.append(_str_to_varstr(p))
	
	for i in len(args):
		if args[i] is Dictionary:
			var d := []
			for k in args[i]:
				d.append('"%s": %s' % [k, args[i][k]])
			args[i] = "{%s}" % ", ".join(d)
	
	var fargs := ", ".join(args)
	var action := "X.%s(%s)" % [fname, fargs]
	return execute_expression(action, null, {X=target})

func _split_string(s: String) -> Array:
	var out := [""]
	var in_quotes := false
	for c in s:
		if c == '"':
			if in_quotes:
				in_quotes = false
				out[-1] += '"'
			else:
				in_quotes = true
				if out[-1] == "":
					out[-1] += '"'
				else:
					out.append('"')
		
		elif c == " " and not in_quotes:
			if out[-1] != "":
				out.append("")
		
		else:
			out[-1] += c
	return out

func _str_to_varstr(s: String) -> String:
	# variable, leave unquoted
	if s.begins_with("$"):
		return s.substr(1)
	
	elif s.begins_with('"'):
		return s
	
	# array
	elif "," in s:
		var p := s.split(",")
		for i in len(p):
			p[i] = _str_to_varstr(p[i])
		return "[%s]" % ", ".join(p)
	
	# leave unquoted
	elif "|" in s or s in ["true", "false", "null"] or s.is_valid_int() or s.is_valid_float():
		return s
	
	# string
	return '"%s"' % s
