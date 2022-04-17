@tool
extends CodeEdit

# richtextlabel tags
var TAG_DESC := {
	# font
	"Bold": { "insert": "b", "icon": ICON_STR },
	"Italics": { "insert": "i", "icon": ICON_STR },
	"Bold italics": { "insert": "bi", "icon": ICON_STR },
	"Underline": { "insert": "u", "icon": ICON_STR },
	"Strike through": { "insert": "s", "icon": ICON_STR },
	"Monospaced": { "insert": "code", "icon": ICON_STR },
	
	# size
	"Resize 1.5x": { "insert": "1.5", "icon": ICON_RESIZE },
	"Resize 2x": { "insert": "2.0", "icon": ICON_RESIZE },
	"Resize .5x": { "insert": "50", "icon": ICON_RESIZE },
	
	# color
	"Darken 33%": { "insert": "dim", "icon": ICON_COLOR },
	"Darken 50%": { "insert": "dim 50", "icon": ICON_COLOR },
	"Lighten 33%": { "insert": "lit", "icon": ICON_COLOR },
	"Lighten 50%": { "insert": "lit 50", "icon": ICON_COLOR },
	"Shift hue": { "insert": "hue", "icon": ICON_COLOR },
	"Shift hue triune 1": { "insert": "hue -33", "icon": ICON_COLOR },
	"Shift hue triune 2": { "insert": "hue 33", "icon": ICON_COLOR },
	
	# emojis
	"Emoji": {"insert": "::", "icon": ICON_PRINT },
	
	# brackets
	"Left bracket": { "insert": "lb", "icon": ICON_PRINT },
	"Right bracket": { "insert": "rb", "icon": ICON_PRINT },
	
	# other
	"Hint": { "insert": "hint \"Hello world!\"", "icon": ICON_PRINT },
	"Link": { "insert": "meta \"www.google.com\"", "icon": ICON_PRINT },
	"Link with hint": { "insert": "meta \"Link text\" \"Hint text\"", "icon": ICON_PRINT },
	
	# inline state
	"Do @node action": { "insert": "@", "icon": ICON_PRINT },
	"Do $state action": { "insert": "$", "icon": ICON_PRINT },
	"Do ^persistent state action": { "insert": "^", "icon": ICON_PRINT },
	"Do ~evaluation": { "insert": "~", "icon": ICON_PRINT },
	
	# animations
	"Do delayed @node action": { "insert": "!@", "icon": ICON_CALL },
	"Do delayed $state action": { "insert": "!$", "icon": ICON_CALL },
	"Do delayed ^persistent state action": { "insert": "!^", "icon": ICON_CALL },
	"Do delayed ~evaluation": { "insert": "!~", "icon": ICON_CALL },
	
	# align
	"Align left": {"insert": "left", "icon": ICON_ALIGN },
	"Alight right": {"insert": "right", "icon": ICON_ALIGN },
	"Align center": {"insert": "center", "icon": ICON_ALIGN },
	"Align fill": {"insert": "fill", "icon": ICON_ALIGN },
}

const SootHighlighter = preload("res://addons/sooty_engine/editor/DialogueHighlighter.gd")

const ICON_ARRAY := preload("res://addons/sooty_engine/icons/var_array.png")
const ICON_BOOL := preload("res://addons/sooty_engine/icons/var_bool.png")
const ICON_COLOR := preload("res://addons/sooty_engine/icons/var_color.png")
const ICON_DICT := preload("res://addons/sooty_engine/icons/var_dict.png")
const ICON_INT := preload("res://addons/sooty_engine/icons/var_int.png")
const ICON_OBJ := preload("res://addons/sooty_engine/icons/var_obj.png")
const ICON_STR := preload("res://addons/sooty_engine/icons/var_str.png")
const ICON_ENUM := preload("res://addons/sooty_engine/icons/var_enum.png")
const ICON_OBJECT := preload("res://addons/sooty_engine/icons/var_obj.png")
#
const ICON_METHOD := preload("res://addons/sooty_engine/icons/generic_method.png") 
const ICON_SIGNAL := preload("res://addons/sooty_engine/icons/generic_signal.png") 

const ICON_NODE_ACTION := preload("res://addons/sooty_engine/icons/node_action.png")
const ICON_NODE_OBJECT := preload("res://addons/sooty_engine/icons/node_object.png")

# rich text tags
const ICON_EFFECT := preload("res://addons/sooty_engine/icons/effects.png")
const ICON_EMOJI := preload("res://addons/sooty_engine/icons/emoji.png")
const ICON_MOTION := preload("res://addons/sooty_engine/icons/motion.png")
const ICON_CALL := preload("res://addons/sooty_engine/icons/call.png")
const ICON_PRINT := preload("res://addons/sooty_engine/icons/print.png")
const ICON_ALIGN := preload("res://addons/sooty_engine/icons/align.png")
const ICON_RESIZE := preload("res://addons/sooty_engine/icons/resize.png")

@export var plugin_instance_id: int

var rte_info := {}
func _get_rich_text_effect_info():
	if not len(rte_info):
		for file in UFile.get_files("res://addons/rich_text/text_effects", ".gd"):
			var rte = load(file)
			if "INFO" in rte:
				var info: Dictionary = rte.INFO
				rte_info[info.code] = info
	return rte_info
	
func _init() -> void:
	if not has_meta("initialized"):
		set_meta("initialized", true)
		# custom highlighter
		syntax_highlighter = SootHighlighter.new()
		
		# allow selecting symbols
		symbol_lookup.connect(_symbol_lookup)
		symbol_validate.connect(_symbol_validate)
		symbol_lookup_on_click = true
		
		# prevent tabs breaking when there is an `'`
		delimiter_strings = []
	#	add_comment_delimiter("#", "", true)
		
		# helpful auto completes
		auto_brace_completion_pairs = {
#			'"': '"',
#			"'": "'",
			"`": "`",
#			"(": ")",
			"[": "]",
			"{": "}",
			"**": "**", # markdown bold
			"<": ">"	# lists
		}
		
		# code completion, to help remember node names
		code_completion_enabled = true
		code_completion_requested.connect(_code_completion_requested)
		code_completion_prefixes = [
			# flow lists
			"/",
			".",
			# actions
			"$",
			"@",
			"^",
			# action arg divider
			" ",
			# eval
			"~",	# start
			"(",	# args begin
			",",	# arg
			# bbcode
			"[",	# start
			";",	# divider
			":"		# emoji
		]

func _var_to_str(vari: Variant, is_action: bool) -> String:
	if is_action:
		var out = str(vari)
		if " " in out:
			return '"%s"' % out
		return out
	else:
		return var2str(vari)

# show code completion for an argument of a method
# in is_action mode, arguments don't need to be wrapped in "" if they have no spaces.
# it looks cleaner to me
func _show_arg(object: Object, arg_info: Dictionary, is_action := false) -> bool:
	var found_at_least_one := false
	
	# is there a function that returns auto complete options?
	if "options" in arg_info:
		var icon: Texture = arg_info.get("icon", null)
		for option in arg_info.options.call():
			found_at_least_one = true
			var display: String = option#"%s: %s" % [arg_info.name.capitalize(), option]
			var insert = UStringConvert.to_type(option, arg_info.type)
			insert = _var_to_str(insert, is_action)
			add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, Color.WHITE, icon, 1)
	
	else:
		if arg_info.type is String:
			# is class_name?
			if UClass.exists(arg_info.type):
				var database: Database = Database.get_database(arg_info.type)
				if database:
					var classname: String = arg_info.name.capitalize()
					for object_id in database.get_all_ids():
						found_at_least_one = true
						var display: String = "%s:%s" % [object_id, classname]
						var insert: String = object_id
						add_code_completion_option(CodeEdit.KIND_CLASS, display, insert, Color.WHITE, ICON_OBJECT)
			
			# is enum?
			else:
				for enum_name in object[arg_info.type]:
					var enum_index: int = object[arg_info.type][enum_name]
					var display: String = "%s.%s" % [arg_info.type, enum_name]
					var insert: String = "%s" % [enum_index] if not is_action else _var_to_str(enum_name, is_action)
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_ENUM, display, insert, Color.WHITE, ICON_ENUM)
		
		# for each type, see if there are options that can be returned
		else:
			var icon: Texture = null
			var options := {}
			match arg_info.type:
				TYPE_BOOL:
					icon = ICON_BOOL
					options = {"true":"true", "false":"false"}
				_:
					if "default" in arg_info:
						options = {"default": var2str(arg_info.default) }
					else:
						options = {"Ignore": "_"}
			
			for display in options:
				found_at_least_one = true
				var insert: String = options[display]
				display = "%s: %s" % [arg_info.name.capitalize(), display]
				add_code_completion_option(CodeEdit.KIND_ENUM, display, insert, Color.WHITE, icon)
	
	return found_at_least_one

# try to find out if we're inside a bbcode
func _get_bbcode(s: String, at: int) -> Variant:
	var start := at
	var found_start := false
	while start >= 0:
		if s[start] == "[":
			found_start = true
			break
		# we are definitly outside of a tag
		if s[start] == "]":
			break
		start -= 1
	
	if not found_start:
		return
	
	var end := at
	var found_end := false
	while end < len(s):
		if s[end] == "]":
			found_end = true
			break
		# we are definitly outside a tag
		if s[end] == "[":
			break
		end += 1
	
#	var inner: String
#	if found_end:
#		inner = s.substr(start, end-start+1)
#	else:
#		inner = s.substr(start)
	
	# second pass: finding the tag
	var start_inner := at
	while start_inner > start:
		if s[start_inner] == ";":
			break
		start_inner -= 1
	var end_inner := at
	while end_inner < min(len(s), end):
		if s[end_inner] == ";":
			break
		end_inner += 1
	
	var inner = s.substr(start_inner, end_inner-start_inner+1)
	return inner

func _get_node_and_method(input: String, is_action := false) -> Dictionary:
	var head := input
	var method := ""
	var args := []
	var arg_index := 0
	
	if is_action:
		args = UString.split_outside(input, " ")
		arg_index = input.count(" ")
		head = args.pop_front()
	else:
		head = input
	
	# find the node
	var node: Node
	var group := head
	if "." in head:
		var p := head.split(".", true, 1)
		group = "@:" + p[0]
		method = p[1]
	else:
		method = group
		group = "@." + group
	
	node = get_tree().get_first_node_in_group(group)
	
	if is_action:
		args.push_front(method)
		method = " ".join(args)
	
	var out := {node=node, method=method, arg_index=arg_index}
	return out

func _code_completion_requested():
	var line := get_caret_line()
	var line_text := get_line(line)
	var line_stripped := line_text.strip_edges(true, false)
	var head := UString.get_leading_symbols(line_stripped)
	var found_at_least_one := false
	var after := line_text.substr(get_caret_column()).strip_edges()
	
	var bbcode_info = _get_bbcode(line_text, get_caret_column()-1)
	if bbcode_info:
		# only look at the last tag
		bbcode_info = UString.trim_amount(bbcode_info)#.rsplit(";", true, 1)[-1]
		
		# in line action
		if bbcode_info.begins_with("!") and len(bbcode_info) >= 2 and bbcode_info[1] in "@$^~":
			bbcode_info = bbcode_info.substr(1)
		
		# ~@$^ actions
		if _test_for_actions(bbcode_info):
			found_at_least_one = true
		
		# :emojis:
		elif bbcode_info == ":" or (bbcode_info.begins_with(":") and not bbcode_info.ends_with(":")):
			found_at_least_one = true
			for emoji_name in Emoji.NAMES:
				var display = emoji_name.capitalize()
				var insert = "%s:" % emoji_name
				add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, Color.WHITE, ICON_EMOJI)
		
		# normal tag
		elif bbcode_info == "" or bbcode_info.ends_with(";"):
			found_at_least_one = true
			# main tags
			for k in TAG_DESC:
				var info = TAG_DESC[k]
				var display = k
				var insert = info.insert
				add_code_completion_option(CodeEdit.KIND_FILE_PATH, display, insert, Color.WHITE, info.icon)
			
			# effects
			var rte := _get_rich_text_effect_info()
			for k in rte:
				var info = rte[k]
				var display = k[0].capitalize() + k.substr(1)
				var insert = k
				if "desc" in info:
					display += ": " + info.desc
				if "auto" in info:
					insert = info.auto
				add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, Color.WHITE, ICON_EFFECT)
			
			# color names
			var clr := Color.WHITE
			for i in UColor.HUE_SORTED:
				var c := clr.get_named_color(i)
				var n := clr.get_named_color_name(i).to_lower()
				var display := "%s %s" % [n, c]
				var insert := n.to_lower()
				add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, c, ICON_COLOR)
	
	# ignore these heads
	elif head in ["===", "---", "=+=", "&", "#", "{{", "{(", "{<"]:
		pass
		
	elif head in ["=>", "=="]:
		var path := _find_flow(line_text, line)
		var base1 := after.get_base_dir()
		var base2 := path.get_base_dir() + "/" if path.get_base_dir() else ""
		
		var paths := Dialogue._flows.keys()\
			.filter(func(x): return x.begins_with(base2))\
			.map(func(x): return x.trim_prefix(base2))\
			.map(func(x): return base1.plus_file(x))
		
		for p in paths:
			found_at_least_one = true
			add_code_completion_option(CodeEdit.KIND_FILE_PATH, p, p)
	
	elif _test_for_actions(line_stripped):
		found_at_least_one = true
	
	if found_at_least_one:
		update_code_completion_options(true)

func _test_for_actions(s: String) -> bool:
	var found_at_least_one := false
	
	# eval
	if s.begins_with("~"):
		if _as_eval():
			found_at_least_one = true
	
	# @action shortcuts
	elif s.begins_with("@"):
		var na := _get_node_and_method(s.substr(1), true)
		if na.node:
			if _as_state_action(na.node, na.method, true):
				found_at_least_one = true
		else:
			if _show_all_node_actions(true):
				found_at_least_one = true
	
	# $state shortcuts
	elif s.begins_with("$"):
		if _as_state_action(State, s.substr(1), true):
			found_at_least_one = true
	
	# ^ persistent state shortcut
	elif s.begins_with("^"):
		if _as_state_action(Persistent, s.substr(1), true):
			found_at_least_one = true
	
	return found_at_least_one

func _as_eval() -> bool:
	var found_at_least_one := false
	
	# figure out which argument we are trygin to write
	var func_data = _find_function()
	
	# are we inside the function?
	if func_data:
		var method: String = func_data.method
		if method.begins_with("["):
			method = method.substr(1).strip_edges()
		if method.begins_with("~"):
			method = method.substr(1).strip_edges()
		
		# inside a function
		if method.begins_with("@"):
			var nm := _get_node_and_method(method.substr(1))
			if nm.node:
				if _show_method_args(nm.node, nm.method, func_data.arg_index):
					found_at_least_one = true
			else:
				if _show_all_node_actions():
					found_at_least_one = true
			
		elif method.begins_with("$"):
			if _show_method_args(State, method.substr(1), func_data.arg_index):
				found_at_least_one = true
		elif method.begins_with("^"):
			if _show_method_args(Persistent, method.substr(1), func_data.arg_index):
				found_at_least_one = true
	
	# we are outside, writing the functio name
	else:
		var method := UString.get_symbol(get_line(get_caret_line()), get_caret_column()-1)
		
		if method.begins_with("["):
			method = method.substr(1).strip_edges()
		if method.begins_with("~"):
			method = method.substr(1).strip_edges()
		
		if method.begins_with("@"):
			var nm := _get_node_and_method(method.substr(1))
			if nm.node:
				if _show_object_actions(nm.node):
					found_at_least_one = true
			else:
				if _show_all_node_actions():
					found_at_least_one = true
		
		elif method.begins_with("$"):
			if _show_object_actions(State):
				found_at_least_one = true
		elif method.begins_with("^"):
			if _show_object_actions(Persistent):
				found_at_least_one = true
	
	return found_at_least_one

func _show_all_node_actions(is_action := false) -> bool:
	var found_at_least_one := false
	var node_action_groups: Array = UGroup.get_all()\
		.map(func(x): return str(x))\
		.filter(func(x): return x.begins_with("@"))
	
	# show all actions
	for node_action in node_action_groups:
		# @. node functions
		if node_action.begins_with("@."):
			# find parent, so we can get it's argument info
			# it won't be null
			var object = get_tree().get_first_node_in_group(node_action)
			var method_info = UReflect.get_method_info(object, node_action.substr(2))
			if method_info:
				# find an icon for the method
				var icon: Texture = ICON_NODE_ACTION
				if "icon" in method_info:
					# if an int is returned, it's assumed to be a type
					if method_info.icon is int:
						icon = _get_type_icon(object, method_info.icon)
				var action_name: String = node_action.substr(2)
				var display: String = method_info.desc if "desc" in method_info else "%s %s" % [action_name.capitalize(), _get_arg_string(method_info)]
				var insert: String = action_name
				found_at_least_one = true
				add_code_completion_option(CodeEdit.KIND_FUNCTION, display, insert, Color.WHITE, icon)
			else:
				push_error("No method %s() in %s." % [node_action.substr(2), object])
		
		# @: node objects
		elif node_action.begins_with("@:"):
			found_at_least_one = true
			node_action = node_action.substr(2)
			add_code_completion_option(CodeEdit.KIND_FUNCTION, node_action, node_action, Color.WHITE, ICON_NODE_OBJECT)
	
	return found_at_least_one

func _as_state_action(object: Object, line_text: String, is_action := false) -> bool:
	var inner: String = line_text.strip_edges(true, false)
	var found_at_least_one := false
	var args := UString.split_outside(inner, " ")
	
	# a subpath to a deeper object?
	if "." in args[0]:
		var p = args[0].rsplit(".", true, 1)
		object = object._get(p[0])
		args[0] = p[1]
	
	if object:
		# arguments:
		# are we passed writing the method
		# and at the point of writing arguments?
		if len(args) > 1 and args[-1] == "":
			# subtract one, as it was the method name
			var method: String = args[0]
			var arg_index := len(args)-2
			if _show_method_args(object, method, arg_index, true):
				found_at_least_one = true
		
		# functions:
		else:
			if _show_object_actions(object, true):
				found_at_least_one = true
	
	return found_at_least_one

func _show_method_args(object: Object, method: String, arg_index: int, is_action := false) -> bool:
	var found_at_least_one := false
	
	# we need to get the method list in a roundabout way
	# because of State and Persistent being made up of subnodes.
	var method_info = UReflect.get_method_info(object, method)
	
	# is it a method?
	if method_info:
		var arg_info = UList.getor(method_info.args.values(), arg_index)
		if arg_info and _show_arg(object, arg_info, is_action):
			found_at_least_one = true
	
	# is it a signal?
	elif object.has_signal(method):
		# TODO
		push_warning("todo: signal arguments")
	
	# is it a property?
	elif method in object:
		push_warning("'%s' is a property in %s. It can't take arguments." % [method, object])
	
	return found_at_least_one

func _show_object_actions(object: Object, is_action := false) -> bool:
	var keys = UObject.get_state_properties(object)
	var found_at_least_one := false
	
	# display every property, with icon based on type
	for insert in keys:
		var icon: Texture = null
		var display: String = insert
		if UObject.has_property(object, insert):
			var val = object[insert]
			display = "%s: %s" % [display, val]
			icon = _get_type_icon(object, typeof(val))
	
		found_at_least_one = true
		add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, Color.WHITE, icon)
	
	# methods
	var methods = UReflect.get_methods(object)
	for method in methods:
		var method_info: Dictionary = methods[method]
		var method_args := _get_arg_string(method_info)
		var display: String = "%s%s" % [method, method_args]
		var insert: String = method if is_action else "%s()" % method
		found_at_least_one = true
		add_code_completion_option(CodeEdit.KIND_FUNCTION, display, insert, Color.LIGHT_BLUE, ICON_METHOD)
	
	# signals
	if not is_action:
		for signal_name in UObject.get_script_signals(object):
			var display: String = signal_name
			var insert: String = "%s.emit()" % signal_name
			found_at_least_one = true
			add_code_completion_option(CodeEdit.KIND_SIGNAL, display, insert, Color.LIGHT_GOLDENROD, ICON_SIGNAL)
	
	return found_at_least_one

func _get_type_icon(object: Object, type: Variant) -> Texture:
	match type:
		TYPE_INT, TYPE_FLOAT: return ICON_INT
		TYPE_ARRAY: return ICON_ARRAY
		TYPE_DICTIONARY: return ICON_DICT
		TYPE_BOOL: return ICON_BOOL
		TYPE_STRING: return ICON_STR
		TYPE_COLOR: return ICON_COLOR
		TYPE_OBJECT: return UClass.get_icon(object.get_class(), ICON_OBJ)
	return null

# attempt to find the function at the current cursor position
func _find_function() -> Dictionary:
	var s: String = get_line(get_caret_line())
	var from: int = get_caret_column()-1
	
	# look backwards till we find the start (
	var start := from
	var found_start := false
	while start >= 0 and start < len(s):
		if s[start] == "(":
			found_start = true
			break
		# we are definitly outside of a function
		elif s[start] == ")":
			return {}
		start -= 1
	if not found_start:
		return {}
	
	# ignore if there is a space before the brackets
	if start == 0 or s[start-1] == " ":
		return {}
	
	# look forwards till we find end end )
	var end := from
	var found_end := false
	while end < len(s):
		if s[end] == ")":
			found_end = true
			end += 1
			break
		end += 1
	
	if not found_end:
		end = len(s)
	
	# look backwards from start to find func name
	var f_start := start-1
	while f_start > 0 and s[f_start] in UString.VAR_CHARS_NESTED:
		f_start -= 1
	# extract function name
	var found_func := start-f_start > 0
	if not found_func:
		return {}
	
	# divide the args
	var inner := s.substr(start+1, end-start-1)
	var args := UString.split_outside(inner, ",")
	
	# find the index of the current arg
	var a := start+1
	var arg_index := -1
	for i in len(args):
		a += len(args[i])+1
		if a >= from:
			arg_index = i
		a += 1
	
	# strip method edges
	var method := s.substr(f_start, start-f_start).strip_edges()
	# strip argument edges
	args = args.map(func(x): return x.strip_edges())
	var out = {method=method, args=args, arg_index=arg_index}
	return out

# convert args to a string (that:int, looks:String, like:bool, this:Array)
func _get_arg_string(info: Dictionary) -> String:
	var arg_preview := []
	for id in info.args:
		arg_preview.append("%s:%s" % [id, UType.get_name_from_type(info.args[id].type)])
	return "(%s)" % ", ".join(arg_preview)

func _method_to_strings(method: String, info: Dictionary) -> Array:
	if info:
		var arg_preview := []
		var arg_output := []
		for arg in info.args:
			arg_preview.append("%s: %s" % [arg.name, UType.get_name_from_type(arg.type)])
			if not "default" in arg:
				arg_output.append("%s" % [var2str(UType.get_default(arg.type))])
		return [
			"%s(%s)" % [method, ", ".join(arg_preview)],
			"%s(%s)" % [method, ", ".join(arg_output)]
		]
	return [method, method + "()"]

# go backwards through the lines and try to find the flow/path/to/this/node.
func _find_flow(next: String, line: int) -> String:
	var deep := UString.count_leading(next, "\t")
	var out := []
	out.resize(deep)
	
	# go backwards collecting parent flows
	while line >= 0:
		var s := get_line(line)
		var sdeep := UString.count_leading(s, "\t")
		if sdeep <= deep:
			var strip := s.strip_edges(true, false)
			if strip.begins_with("==="):
				out[sdeep] = strip.split("===", true, 1)[-1].strip_edges()
		line -= 1
	
	# add self to the path
	next = next.strip_edges()
	var head := UString.get_leading_symbols(next)
	next = next.trim_prefix(head).strip_edges()
	
	# create path
	var path := Flow._get_flow_path("/".join(out), next)
	return path
	
func _symbol_validate(symbol: String):
	var line_col := get_line_column_at_pos(get_local_mouse_pos())
	var line_text := get_line(line_col.y).strip_edges(true, false)
	var head := UString.get_leading_symbols(line_text)
	if head in ["===", "=>", "==", "---"]:
		set_symbol_lookup_word_as_valid(true)
	else:
		set_symbol_lookup_word_as_valid(false)

func _symbol_lookup(symbol: String, line: int, column: int):
	var line_col := get_line_column_at_pos(get_local_mouse_pos())
	var line_text := get_line(line_col.y)
	var head := UString.get_leading_symbols(line_text.strip_edges())
	match head:
		"===", "---":
			toggle_foldable_line(line)
		
		# follow through to link
		"=>", "==":
			var path := _find_flow(line_text, line)
			var capped := path.substr(0, path.find(symbol)+len(symbol))
			
			if capped in Dialogue._flows:
				var meta: Dictionary = Dialogue._flows[capped].M
				# select file in FileSystem
				instance_from_id(plugin_instance_id).edit_text_file(meta.file, meta.line)
				
			else:
				push_warning("No path '%s' found." % capped)
