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
	"Resize .5x": { "insert": "0.5", "icon": ICON_RESIZE },
	
	# color
	"Darken 33%": { "insert": "dim", "icon": ICON_COLOR },
	"Lighten 33%": { "insert": "lit", "icon": ICON_COLOR },
	"Shift hue": { "insert": "hue", "icon": ICON_COLOR },
	
	# emojis
	"Emoji": {"insert": "::", "icon": ICON_PRINT },
	
	# brackets
	"Left bracket": { "insert": "lb", "icon": ICON_PRINT },
	"Right bracket": { "insert": "rb", "icon": ICON_PRINT },
	
	# inline state
	"Input @node action": { "insert": "@", "icon": ICON_PRINT },
	"Input $state action": { "insert": "$", "icon": ICON_PRINT },
	"Input ^persistent state action": { "insert": "^", "icon": ICON_PRINT },
	"Input ~evaluation": { "insert": "~", "icon": ICON_PRINT },
	
	# other
	"Hint": { "insert": "hint \"Hello world!\"", "icon": ICON_PRINT },
	"Link": { "insert": "meta \"www.google.com\"", "icon": ICON_PRINT },
	"Link with hint": { "insert": "meta \"Link text\" \"Hint text\"", "icon": ICON_PRINT },
	
	# animations
	"Delayed @node action": { "insert": "!@", "icon": ICON_CALL },
	"Delayed $state action": { "insert": "!$", "icon": ICON_CALL },
	"Delayed ^persistent state action": { "insert": "!^", "icon": ICON_CALL },
	"Delayed ~evaluation": { "insert": "!~", "icon": ICON_CALL },
	
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
		print("getting rte.")
		for file in UFile.get_files("res://addons/rich_text/text_effects", ".gd"):
			var rte = load(file).new()
			if "bbcode" in rte:
				if "info" in rte:
					rte_info[rte.bbcode] = rte.info
				else:
					rte_info[rte.bbcode] = {}
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
		auto_brace_completion_pairs["`"] = "`"
		auto_brace_completion_pairs["<"] = ">"
		auto_brace_completion_pairs["**"] = "**"
		
		# code completion, to help remember node names
		code_completion_enabled = true
		code_completion_requested.connect(_code_completion_requested)
		code_completion_prefixes = ["/", ".", "$", "@", "^", ",", " ", "(", "[", ";"]

func _get_func_info(fname: String) -> Array:
	var object: String = ""
	var method: String = fname
	
	if "." in fname:
		var p := fname.split(".", true, 1)
		object = p[0]
		method = p[1]
		
	if fname.begins_with("@"):
		if "." in fname:
			var p := fname.trim_prefix("@").split(".", true, 1)
			object = p[0]
			method = p[1]
			var node := get_tree().get_first_node_in_group("@:" + object)
			if node:
				return [node, UScript.get_method_info(node, method)]
		else:
			var node := get_tree().get_first_node_in_group("@." + object)
			if node:
				return [node, UScript.get_method_info(node, method)]
	
	return []

func var_to_str(vari: Variant, is_action: bool) -> String:
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
		for op in arg_info.options.call():
			found_at_least_one = true
			var insert = UStringConvert.to_type(op, arg_info.type)
			insert = var_to_str(insert, is_action)
			add_code_completion_option(CodeEdit.KIND_VARIABLE, op, insert, Color.WHITE, null, 1)
	else:
		if arg_info.type is String:
			
			# is class_name?
			if UClass.exists(arg_info.type):
				var manager: DataManager = DataManager.get_manager(arg_info.type)
				if manager:
					for object_id in manager.get_all_ids():
						found_at_least_one = true
						var display: String = object_id
						var insert: String = object_id
						add_code_completion_option(CodeEdit.KIND_CLASS, display, insert, Color.WHITE, ICON_OBJECT)
			
			# is enum?
			else:
				for enum_name in object[arg_info.type]:
					found_at_least_one = true
					var display: String = "%s.%s" % [arg_info.type, enum_name]
					var insert: String = var_to_str(enum_name, is_action)
					add_code_completion_option(CodeEdit.KIND_ENUM, display, insert, Color.WHITE, ICON_ENUM)
		
		# for each type, see if there are options that can be returned
		else:
			var icon: Texture = null
			var options := {}
			match arg_info.type:
				TYPE_BOOL:
					icon = ICON_BOOL
					options = {"true":"true", "false":"false"}
			
			for o in options:
				found_at_least_one = true
				add_code_completion_option(CodeEdit.KIND_ENUM, o, options[o], Color.WHITE, icon)
	
	return found_at_least_one

func _code_completion_requested():
	var line := get_caret_line()
	var line_text := get_line(line)
	var line_stripped := line_text.strip_edges()
	var head := UString.get_leading_symbols(line_stripped)
	var found_at_least_one := false
	var after := line_text.substr(get_caret_column()).strip_edges()
	
	if head in ["===", "---", "=+=", "&", "#", "{{", "{(", "{<"]:
		pass
	
	# bbcode tags
	elif head in ["[", ";"]:
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
		for i in UClr.HUE_SORTED:
			var c := clr.get_named_color(i)
			var n := clr.get_named_color_name(i)
			var display := "Color.%s %s" % [n, c]
			var insert := n.to_lower()
			add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, c, ICON_COLOR)
		
		# emojis
#		for emoji_name in Emoji.NAMES:
#			var display = "Emoji %s" % [emoji_name.capitalize()]
#			var insert = ":%s:" % emoji_name
#			add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, Color.WHITE, ICON_EMOJI)
		
		
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
	
	elif head == "~":
		# figure out which argument we are trygin to write
		var arg_data = _find_function(line_text, get_caret_column())
		# get the functions argument info
		var func_info = _get_func_info(arg_data.get("method", ""))
		# find the info for this specific argument
		if func_info:
			var object: Object = func_info[0]
			if arg_data.current_arg >= len(func_info[1].args):
				push_warning("ARG OUT OF BOUNDS")
			
			else:
				# information for current argument being typed
				var arg_info = func_info[1].args.values()[arg_data.current_arg]
				if _show_arg(object, arg_info):
					found_at_least_one = true
	
	# action shortcuts
	elif head == "@":
		var method: String = line_text.strip_edges().substr(1)
		var node_action_groups: Array = UGroup.get_all()\
			.map(func(x): return str(x))\
			.filter(func(x): return x.begins_with("@"))
		
		# . in action means it is a function call or property accesor
		if "." in method:
			var p = method.split(".", true, 1)
			var group = p[0]
			method = p[1]
			var parts := UString.split_outside(method, " ")
			var all_methods: Dictionary = {}
			
			var node: Node = get_tree().get_first_node_in_group("@:" + group)
			if node:
				all_methods = UScript.get_method_infos(node)
			
			# still writing the function name
			# so show a list of all possible functions
			if len(parts) == 0:
				for method in all_methods:
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_VARIABLE, method, method, Color.WHITE, ICON_NODE_ACTION)
			
			# at the point of writing arguments
			else:
				var meth_info = all_methods.get(parts[0], {})# data.get("@:" + group, {}).funcs.get(parts[0], {})
				var arg_index: int = len(parts)-2
				if meth_info and arg_index < len(meth_info.args):
#					print("@:" + method, meth_info.args[arg_index], len(parts), parts)
					prints(group, parts[0], arg_index)
					if group == "Music" and parts[0] == "play" and arg_index == 0:
						var music = Music._files.keys()
						print("MUSIC ", music)
						for song in music:
							found_at_least_one = true
							var s2 = ('"%s"' % song) if " " in song else song
							add_code_completion_option(CodeEdit.KIND_VARIABLE, song, s2, Color.WHITE, ICON_NODE_ACTION)
		# no dot, means we may want to show all
		# @: node_objects
		# and
		# @. node_functions
		else:
			for node_action in node_action_groups:
				if node_action.begins_with("@."):
					var node: Node = get_tree().get_first_node_in_group("@." + node_action)
					var method_info := {}
					if node:
						method_info = UScript.get_method_info(node, node_action.substr(2))
					var p = _get_node_action_strings(node_action.substr(2), method_info)#data[node_action])
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_VARIABLE, p[0], p[1], Color.WHITE, ICON_NODE_ACTION)
				elif node_action.begins_with("@:"):
					found_at_least_one = true
					node_action = node_action.substr(2)
					add_code_completion_option(CodeEdit.KIND_VARIABLE, node_action, node_action, Color.WHITE, ICON_NODE_OBJECT)

	# state shortcuts
	elif head == "$" or head == "^":
		var keys := []
		var object: Object = State if head == "$" else Persistent
		var inner: String = line_text.strip_edges(true, false).substr(1)
		var parts := UString.split_outside(inner, " ")
		UDebug.log(inner, parts)
		var path: String = parts.pop_front()
		
		# a subpath to a deeper object?
		if "." in path:
			var p := path.rsplit(".", true, 1)
			object = object._get(p[0])
		
		if object:
			# are we passed writing the method
			# and at the point of writing arguments?
			if parts and parts[-1] == "":
				# subtract one, as it was the method name
				var arg_index := len(parts)-1
				
				# we need to do this in a roundabout way
				# because of State and Persistent being made up of subnodes.
				var method_info = UScript.get_script_methods(object)
				
				# is it a method?
				if path in method_info:
					var arg_info = UList.getor(method_info[path].args.values(), arg_index)
					if arg_info and _show_arg(object, arg_info, true):
						found_at_least_one = true
				
				# is it a signal?
				elif object.has_signal(path):
					# TODO
					pass
				
				# is it a property?
				elif path in object:
					push_warning("'%s' is a property in %s. It can't take arguments." % [path, object])
					pass
			
			else:
				keys = UObject.get_state_properties(object)
				
				# display every property, with icon based on type
				for insert in keys:
					var icon: Texture = null
					var display: String = insert
					if UObject.has_property(object, insert):
						var val = object[insert]
						display = "%s: %s" % [display, val]
						match typeof(val):
							TYPE_INT, TYPE_FLOAT: icon = ICON_INT
							TYPE_ARRAY: icon = ICON_ARRAY
							TYPE_DICTIONARY: icon = ICON_DICT
							TYPE_BOOL: icon = ICON_BOOL
							TYPE_STRING: icon = ICON_STR
							TYPE_COLOR: icon = ICON_COLOR
							TYPE_OBJECT: icon = UClass.get_icon(val.get_class(), ICON_OBJ)
				
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_VARIABLE, display, insert, Color.WHITE, icon)
				
				# methods
				var methods = UScript.get_script_methods(object)
				for method in methods:
					var method_info: Dictionary = methods[method]
					var method_args := " ".join(UList.map_dict(method_info.args, func(k, v): return "%s:%s" % [k, UType.get_name_from_type(v.type)]))
					var display: String = "%s %s" % [method, method_args]
					var insert: String = method
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_FUNCTION, display, insert, Color.LIGHT_BLUE, ICON_METHOD)
				
				# signals
				for k in UObject.get_script_signals(object):
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_SIGNAL, k, k + ".emit()", Color.LIGHT_GOLDENROD, ICON_SIGNAL)

#	else:
#		var symbol: String = UString.get_symbol(line_text, get_caret_column()-1, "$@")
#		head = UString.get_leading_symbols(symbol)
#		symbol = symbol.trim_prefix(head)
#
#		if head == "$":
#			
#
#		elif head == "@":
#			var data = UFile.load_from_resource("res://debug_output/all_groups.tres", [])
#			if "." in symbol:
#				print(symbol)
#				var group_id := symbol.split(".", true, 1)[0]
#				var node_info: Dictionary = data.get("@:%s" % group_id, {})
#				var methods: Dictionary = node_info.funcs
#				for method in methods:
#					found_at_least_one = true
#					var s := _method_to_strings(method, methods[method])
#					add_code_completion_option(CodeEdit.KIND_FUNCTION, s[0], s[1], Color.LIGHT_BLUE, ICON_METHOD)
#
#			else:
#				# show all
#				for k in data:
#					var clr = Color.WHITE if k.begins_with("@.") else Color.TURQUOISE
#					k = k.substr(2)
#					found_at_least_one = true
#					add_code_completion_option(CodeEdit.KIND_MEMBER, k, k, clr)
	
	if found_at_least_one:
		update_code_completion_options(true)

func _find_function(s: String, from: int):
	if from > len(s):
		from -= 1
	
	# look backwards till we find the start (
	var start := from
	var found_start := false
	while start > 0:
		if s[start] == "(":
			found_start = true
			break
		start -= 1
	if not found_start:
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
		return {}
	
	# ignore if there is a space before the brackets
	if start == 0 or s[start-1] == " ":
		return {}
	
	# look backwards from start to find func name
	var f_start := start
	while f_start > 0 and not s[f_start] in " \t":
		f_start -= 1
	# extract function name
	var found_func := start-f_start > 0
	if not found_func:
		return {}
	
	# divide the args
	var inner := s.substr(start+1, end-start-2)
	var args := UString.split_outside(inner, ",")
	
	# find the index of the current arg
	var a := start+1
	var arg_index := -1
	for i in len(args):
		a += len(args[i])
		if a >= from:
			arg_index = i
		a += 1
	
	# strip method edges
	var method := s.substr(f_start, start-f_start).strip_edges()
	# strip argument edges
	args = args.map(func(x): return x.strip_edges())
	return {method=method, args=args, current_arg=arg_index}

#func _get_method_strings(target: Object, method: String) -> Array:
#	var info := UScript.get_method_info(target, method)
#	return _method_to_strings(method, info)

func _get_node_action_strings(method: String, info: Dictionary) -> Array:
	var arg_preview := [method]
	var arg_output := [method]
	if "args" in info:
		for arg in info.args:
			arg_preview.append("%s:%s" % [arg.name, UType.get_name_from_type(arg.type)])
			if not "default" in arg:
				arg_output.append("%s" % [var2str(UType.get_default(arg.type))])
	return [
		" ".join(arg_preview),
		" ".join(arg_output)
	]

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
