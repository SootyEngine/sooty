@tool
extends CodeEdit

const SootHighlighter = preload("res://addons/sooty_engine/editor/DialogueHighlighter.gd")

const ICON_ARRAY := preload("res://addons/sooty_engine/icons/var_array.png")
const ICON_BOOL := preload("res://addons/sooty_engine/icons/var_bool.png")
const ICON_COLOR := preload("res://addons/sooty_engine/icons/var_color.png")
const ICON_DICT := preload("res://addons/sooty_engine/icons/var_dict.png")
const ICON_INT := preload("res://addons/sooty_engine/icons/var_int.png")
const ICON_OBJ := preload("res://addons/sooty_engine/icons/var_obj.png")
const ICON_STR := preload("res://addons/sooty_engine/icons/var_str.png")
#
const ICON_METHOD := preload("res://addons/sooty_engine/icons/generic_method.png") 
const ICON_SIGNAL := preload("res://addons/sooty_engine/icons/generic_signal.png") 

const ICON_NODE_ACTION := preload("res://addons/sooty_engine/icons/node_action.png")
const ICON_NODE_OBJECT := preload("res://addons/sooty_engine/icons/node_object.png")

@export var plugin_instance_id: int

func _init() -> void:
	# custom highlighter
	syntax_highlighter = SootHighlighter.new()
	
	# allow selecting symbols
	symbol_lookup.connect(_symbol_lookup)
	symbol_validate.connect(_symbol_validate)
	symbol_lookup_on_click = true
	
	# prevent tabs breaking when there is an `'`
	delimiter_strings = []
	add_comment_delimiter("#", "", true)
	
	# helpful auto completes
	auto_brace_completion_pairs["`"] = "`"
	auto_brace_completion_pairs["<"] = ">"
	auto_brace_completion_pairs["**"] = "**"
	
	# code completion, to help remember node names
	code_completion_enabled = true
	code_completion_requested.connect(_code_completion_requested)
	code_completion_prefixes = ["/", ".", "$", "@"]

func _code_completion_requested():
	var line := get_caret_line()
	var line_text := get_line(line)
	var line_stripped := line_text.strip_edges()
	var head := UString.get_leading_symbols(line_stripped)
	var found_at_least_one := false
	var after := line_text.substr(get_caret_column()).strip_edges()
	
	if head in ["=>", "=="]:
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
	
	# action shortcuts
	elif head == "@":
		var data = UFile.load_from_resource("res://debug_output/all_groups.tres", {})
		var method = line_text.strip_edges().substr(1)
		if "." in method:
			var p = method.split(".", true, 1)
			var group = p[0]
			method = p[1]
			var parts := UString.split_outside(method, " ")
			
			# still writing the function name
			if len(parts) == 0:
				var all_methods = data.get("@:" + group, {}).funcs
				for method in all_methods:
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_VARIABLE, method, method, Color.WHITE, ICON_NODE_ACTION)
			
			# at the point of writing arguments
			else:
				var meth_info = data.get("@:" + group, {}).funcs.get(parts[0], {})
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
		else:
			for node_action in data:
				if node_action.begins_with("@."):
					var p = _get_node_action_strings(node_action.substr(2), data[node_action])
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_VARIABLE, p[0], p[1], Color.WHITE, ICON_NODE_ACTION)
				elif node_action.begins_with("@:"):
					found_at_least_one = true
					node_action = node_action.substr(2)
					add_code_completion_option(CodeEdit.KIND_VARIABLE, node_action, node_action, Color.WHITE, ICON_NODE_OBJECT)
	else:
		var symbol: String = UString.get_symbol(line_text, get_caret_column()-1, "$@")
		head = UString.get_leading_symbols(symbol)
		symbol = symbol.trim_prefix(head)
		
		if head == "$":
			var keys := []
			var target: Object = State
			
			if "." in symbol:
				var p := symbol.rsplit(".", true, 1)
				target = State._get(p[0])
				keys = UObject.get_state_properties(target)
			else:
				keys = State._default.keys()
			
			for k in keys:
				var icon: Texture = null
				var display: String = k
				if UObject.has_property(target, k):
					var val = target[k]
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
				add_code_completion_option(CodeEdit.KIND_VARIABLE, display, k, Color.WHITE, icon)
			
			# signals
			for k in UObject.get_script_signals(target):
				found_at_least_one = true
				add_code_completion_option(CodeEdit.KIND_SIGNAL, k, k + ".emit()", Color.LIGHT_GOLDENROD, ICON_SIGNAL)
			
			# methods
			var methods := UObject.get_script_methods(target)
			for method in methods:
				var s := _method_to_strings(method, methods[method])
				found_at_least_one = true
				add_code_completion_option(CodeEdit.KIND_FUNCTION, s[0], s[1], Color.LIGHT_BLUE, ICON_METHOD)
		
		elif head == "@":
			var data = UFile.load_from_resource("res://debug_output/all_groups.tres", [])
			if "." in symbol:
				print(symbol)
				var group_id := symbol.split(".", true, 1)[0]
				var node_info: Dictionary = data.get("@:%s" % group_id, {})
				var methods: Dictionary = node_info.funcs
				for method in methods:
					found_at_least_one = true
					var s := _method_to_strings(method, methods[method])
					add_code_completion_option(CodeEdit.KIND_FUNCTION, s[0], s[1], Color.LIGHT_BLUE, ICON_METHOD)
			
			else:
				# show all
				for k in data:
					var clr = Color.WHITE if k.begins_with("@.") else Color.TURQUOISE
					k = k.substr(2)
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_MEMBER, k, k, clr)
	
	if found_at_least_one:
		update_code_completion_options(false)


func _get_method_strings(target: Object, method: String) -> Array:
	var info := UScript.get_method_info(target, method)
	return _method_to_strings(method, info)

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
