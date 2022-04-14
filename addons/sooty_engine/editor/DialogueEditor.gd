@tool
extends CodeEdit

const SootHighlighter = preload("res://addons/sooty_engine/editor/DialogueHighlighter.gd")

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
	
	else:
		var symbol: String = UString.get_symbol(line_text, get_caret_column()-1, "$@")
		head = UString.get_leading_symbols(symbol)
		symbol = symbol.trim_prefix(head)
		
		if head == "$":
			var keys := []
			
			if "." in symbol:
				var p := symbol.rsplit(".", true, 1)
				var target = State[p[0]]
				keys = UObject.get_state_properties(target)
			else:
				keys = State._default.keys()
			
			for k in keys:
				found_at_least_one = true
				add_code_completion_option(CodeEdit.KIND_VARIABLE, k, k)
		
		elif head == "@":
			var data = UFile.load_from_resource("res://debug_output/all_groups.tres", [])
			if "." in symbol:
				var group_id := symbol.split(".", true, 1)[0]
				var functions: Array = data.get("@:%s" % group_id, [])
				for k in functions:
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_MEMBER, k, k)
			else:
				# show all
				for k in data:
					var clr = Color.WHITE if k.begins_with("@.") else Color.TURQUOISE
					k = k.substr(2)
					found_at_least_one = true
					add_code_completion_option(CodeEdit.KIND_MEMBER, k, k, clr)
	
	if found_at_least_one:
		update_code_completion_options(false)

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
