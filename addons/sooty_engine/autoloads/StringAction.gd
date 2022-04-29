@tool
extends RefCounted

var _expr := Expression.new()
var _state: Object
var _persistent: Object

func _ready():
	var sooty := Global.get_node("/root/Sooty")
	_state = sooty.state
	_persistent = sooty.persistent

# `@:` allow calling as @node_id
static func connect_as_node(node: Node, id: String = ""):
	if id == "":
		# use script name as name
		id = UFile.get_file_name(node.get_script().resource_path)
	node.add_to_group("@:%s" % id)

# `@.` allow calling as @node.method_id
static func connect_methods(methods: Array):
	var node: Node = methods[0].get_object()
	for callable in methods:
		node.add_to_group("@.%s" % callable.get_method())

func _eval_replace_group_call(inside: String, group: String, nested: bool) -> String:
	if nested:
		var p := inside.split("(", true, 1)
		return "_SA_._call_group(\"@:%s\", \"%s\", [%s])" % [group, p[0], p[1]]
	else:
		return "_SA_._call_group(\"@:%s\", \"%s\", [%s])" % [group, group, inside]

# var action := '"%s %s %s %s %s" % [@test.name, @enemy.damage(score), @heal(333)]'
# var action := '[@test.name, @enemy.damage(score), @heal(333)]'
func preprocess_eval(eval: String):
	var tags := [{item="", tail="", is_func=false}]
	var in_tag := true
	for c in eval:
		if in_tag:
			if c in UString.VAR_CHARS_NESTED:
				tags[-1].item += c
			# is method?
			elif c == "(":
				in_tag = false
				tags[-1].tail += c
				tags[-1].is_func = true
			# end of var or method
			elif c in " ,+-/*=!)":
				tags[-1].tail += c
				in_tag = false
		elif c in UString.VAR_CHARS+"@$":
			in_tag = true
			tags.append({item=c, tail="", is_func=false})
		else:
			tags[-1].tail += c
	
	var out := ""
	for t in tags:
		if t.item.begins_with("@"):
			t.item = t.item.substr(1)
			if t.is_func:
				if "." in t.item:
					var p = t.item.split(".", true, 1)
					t.item = "_SA._group_callv(\"@.%s\", \"%s\"" % [p[0], p[1]]
				else:
					t.item = "_SA_._group_callv(\"@:%s\", \"%s\"" % [t.item, t.item]
				t.tail = t.tail.trim_prefix("(") + ", "
			else:
				if "." in t.item:
					var p = t.item.split(".", true, 1)
					t.item = "_SA_.get_group_property(\"@.%s\", \"%s\")" % [p[0], p[1]]
				else:
					t.item = "_SA_.get_group_property(\"@.%s\")" % [t.item]
		
		elif t.item.begins_with("$"):
			pass
		
		else:
			if t.is_func:
				if not t.item in UObject.GLOBAL_SCOPE_METHODS:
					t.item = t.item.replace("%s(" % t.item, "_calls.%s.call(" % t.item)
		out += t.item + t.tail
	return out
	return eval

func test(e: String, context: Object = null) -> bool:
	# allows @$^ to start with not
	if e.begins_with("not "):
		return not test(e.substr(4).strip_edges())
	elif e == "true":
		return true
	elif e == "false":
		return false
	else:
		return true if do(e, context) else false

func do(command: String, context: Object = null) -> Variant:
	if not len(command):
		return
	
	# MATCH case argument
	if command == "_":
		return "_"
	
	if command.begins_with("@"):
		return do_group_action(command, context)
	
	elif command.begins_with("~"):
		return eval(command.substr(1).strip_edges(), context)
	
	push_error("Do action '%s'." % command)
	return null

func is_action(s: String) -> bool:
	return UString.get_leading_symbols(s) in Soot.ALL_ACTION_HEADS

# to_var keeps everything as strings so you can auto type convert where needed
# but if you want it to auto convert, use this
func var_to_variant(svar: Variant) -> Variant:
	match typeof(svar):
		TYPE_ARRAY:
			var out := []
			for i in len(svar):
				out.append(var_to_variant(svar[i]))
			return out
		
		TYPE_DICTIONARY:
			var out := {}
			for k in svar:
				out[k] = var_to_variant(svar[k])
			return out
		
		TYPE_STRING:
			var head := UString.get_leading_symbols(svar)
			if head in Soot.ALL_ACTION_HEADS:
				return do(svar)
			else:
				return UString.str_to_var(svar)
		_:
			push_error("Shouldn't happen.")
			return svar

# @action
func do_group_action(action: String, context: Object) -> Variant:
	var args := UString.split_outside(action, " ")
	var group: String = args.pop_front()
	return call_group_w_args(group, args, true)

# @action
# while it can call many members of a group, it returns the last non null value it gets
func call_group_w_args(group: String, args: Array, as_string_args := false) -> Variant:
	if group.begins_with("@"):
		group = group.substr(1)
	
	# node call
	var method: String = group
	if "." in group:
		var p = group.split(".", true, 1)
		group = "@:" + p[0]
		method = p[1]
	# function call
	else:
		group = "@." + group
	
	return _group_call(group, method, args, as_string_args)

func _group_call(group: String, method: String, args := [], as_string_args := false) -> Variant:
	var out: Variant
	var nodes := UGroup.get_all(group)
	for node in nodes:
		var got = UObject.call_w_kwargs([node, method], args, as_string_args)
		if got != null:
			out = got
	if len(nodes) == 0:
		push_warning("No nodes in group '%s' to call '%s' on with %s." % [group, method, args])
	return out

const NAR := {t="NULL_ARG"}
func _group_callv(group: String, method: String, a0=NAR, a1=NAR, a2=NAR, a3=NAR, a4=NAR, a5=NAR) -> Variant:
	var out: Variant
	var nodes := UGroup.get_all(group)
	var args := [a0, a1, a2, a3, a4, a5].filter(func(x): x != NAR)
	for node in nodes:
		var got = UObject.call_w_kwargs([node, method], args, false)
		if got != null:
			out = got
	if len(nodes) == 0:
		push_warning("No nodes in group '%s' to call '%s' on with %s." % [group, method, args])
	return out

func get_group_property(group: String, property: String = "") -> Variant:
	var node: Node = UGroup.first(group)
	if property:
		if node:
			var got = node.get(property)
			print("Called %s.%s on %s, got %s." % [group, property, node, got])
			return got
		else:
			push_error("No node for %s.%s." % [group, property])
			return null
	else:
		return null

func _context_has(context: Object, property: String) -> bool:
	if context.has_method("_has"):
		return context._has(property)
	else:
		return property in context

func eval(eval: String, context: Variant = null, default = null) -> Variant:
	if context == null:
		context = _state
	
	# assignments?
	for op in [" = ", " += ", " -= ", " *= ", " /= "]:
		if op in eval:
			var p := eval.split(op, true, 1)
			var property := p[0].strip_edges()
			var target: Object = _state
			
			# assigning to a state variable?
			if property.begins_with("$"):
				property = property.substr(1)
				target = context
			
#			elif property.begins_with("^"):
#				property = property.substr(1)
#				target = Persistent
			
			# assigning to a group object?
			elif property.begins_with("@"):
				property = property.substr(1)
				target = UGroup.first(property)
				push_error("Assigning to @nodes isn't implemented.")
				return
				
			if _context_has(target, property):
				var old_val = target[property]
				var got_val = eval(p[1].strip_edges(), context)
				var new_val = old_val
				match op:
					" = ": new_val = got_val
					" += ": new_val += got_val
					" -= ": new_val -= got_val
					" *= ": new_val *= got_val
					" /= ": new_val /= got_val
				target[property] = new_val
				return target[property]
			else:
				push_error("No property '%s' in %s." % [property, target])
				return default
	
	# state_manager modified this to make it work with all it's child functions
	if context.has_method("_preprocess_eval"):
		eval = context._preprocess_eval(eval)
	
	# state shortcut
	eval = preprocess_eval(eval)
	
	if _expr.parse(eval, ["_T_", "_SA_", "_C_"]) != OK:
		push_error("Failed _eval('%s'): %s." % [eval, _expr.get_error_text()])
	else:
		var result = _expr.execute([Global.get_tree(), self, context], _state, false)
		if _expr.has_execute_failed():
			push_error("Failed _eval('%s'): %s." % [eval, _expr.get_error_text()])
		else:
			return result
	return default

# x = do_something(true, custom_func(0), sin(rotation))
# BECOMES
# x = _C.do_something.call(true, _C.custom_func.call(0), sin(rotation))
# this means functions defined in one Node, are usable by all as if they are their own.
#func _globalize_functions(t: String) -> String:
#	var i := 0
#	var out := ""
#	var off := 0
#	while i < len(t):
#		var j := t.find("(", i)
#		# find a bracket.
#		if j != -1:
#			var k := j-1
#			var method_name := ""
#			# walk backwards
#			while k >= 0 and t[k] in UString.VAR_CHARS_NESTED:
#				method_name = t[k] + method_name
#				k -= 1
#			# if head isn't empty, it's a function not wrapping brackets.
#			if method_name != "":
#				out += UString.part(t, i, k+1)
#				# renpy inspired translation shortcut
#				if method_name == "_":
#					out += "tr("
#				# don't wrap property methods, since those will be globally accessible from _get
#				# don't wrap built in GlobalScope methods (sin, round, randf...)
#				elif "." in method_name or method_name in UObject.GLOBAL_SCOPE_METHODS:
#					out += "%s(" % method_name
#				else:
#					var parent = _state._get_method_parent(method_name)
#					out += "get_node(\"%s\").%s(" % [parent, method_name]
#				out += UString.part(t, k+1+len(method_name), j)
#				i = j + 1
#				continue
#		out += t[i]
#		i += 1
#	# add on the remainder.
#	out += UString.part(t, i)
#	return out
