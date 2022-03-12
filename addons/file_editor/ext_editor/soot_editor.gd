@tool
extends FE_Editor

var flows_opened := true
var choices_opened := true

func _init_settings():
	super._init_settings()
	set_string_delimiters(['" "'])
	self.auto_brace_completion_pairs["*"] = "*"
	self.auto_brace_completion_pairs["|"] = "|"
	self.auto_brace_completion_pairs["<"] = ">"

func _popup_init():
	var m := get_menu()
	m.add_separator()
	m.add_item("Toggle flows", 200)
	m.add_item("Toggle choices", 201)
	m.set_item_shortcut(m.get_item_index(200), FE_Util.str_to_shortcut("ctrl+1"))
	m.set_item_shortcut(m.get_item_index(201), FE_Util.str_to_shortcut("ctrl+2"))
#	m.add_item("Open flows", 201)
#	m.add_item("Close choices", 100)
#	m.add_item("Open choices", 101)

func _shortcut(id):
	match id:
		1: toggle_fold_flows()
		2: toggle_fold_choices()

func _clicked():
	var line := get_line(get_caret_line())
	for type in [">>", "::"]:
		var i := line.rfind(type, get_caret_column())
		if i != -1:
			var link := line.substr(i+len(type)).strip_edges()
			var goto := file.find_chapter_line(link)
			if goto != -1:
				goto(goto)
			else:
				# No chapter? Create it.
				self.text += "\n\n# %s\n\n" % link
				goto(get_line_count())
			return
	
	# otherwise do the typical click
	super._clicked()

func toggle_fold_flows():
	flows_opened = not flows_opened
	
	if flows_opened:
		for i in get_line_count():
			if get_line(i).begins_with("# "):
				unfold_line(i)
	else:
		for i in get_line_count():
			if get_line(i).begins_with("# "):
				fold_line(i)

func toggle_fold_choices():
		choices_opened = not choices_opened
		
		if choices_opened:
			for i in get_line_count():
				if get_line(i).strip_edges(true, false).begins_with("<"):
					unfold_line(i)
		else:
			for i in get_line_count():
				if get_line(i).strip_edges(true, false).begins_with("<"):
					fold_line(i)

func _popup_pressed_id(id :int):
	var menu := get_menu()
	match id:
		200: toggle_fold_flows()
		201: toggle_fold_choices()


func get_comment_head() -> String:
	return "// "
