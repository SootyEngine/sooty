@tool
extends Node

@export var font: Font = preload("res://addons/visual_novel/fonts/font-r.tres")
@export var _graph_edit: NodePath = "VBoxContainer/GraphEdit"
@export var _graph_node_prefab: NodePath
@export var _b_rebuild: NodePath
@onready var graph_edit: GraphEdit = get_node(_graph_edit)
@onready var graph_node_prefab: GraphNode = get_node(_graph_node_prefab)
@onready var b_rebuild: Button = get_node(_b_rebuild)

var is_plugin_hint := false
var plugin # reference to editor plugin. only used in editor version.
var all_graph_nodes := {}
var all_flow_buttons := {}
var goto_nodes := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		graph_edit.remove_child(graph_node_prefab)
		await get_tree().process_frame
		b_rebuild.pressed.connect(_update)
		_update.call_deferred()

func _update():
	all_graph_nodes.clear()
	all_flow_buttons.clear()
	goto_nodes.clear()
	
	UNode.remove_children(graph_edit)
	
	var pos := Vector2.ZERO
	var clr_gray := Color(.33, .33, .33, 1.0)
	
	print("DIALOGUES ", Dialogues.cache.keys())
	
	for d_id in Dialogues.cache:
		if not d_id in ["demo", "demo2"]:
			continue
		
		var dialogue: Dialogue = Dialogues.cache[d_id]
		var graph_node: GraphNode = graph_node_prefab.duplicate()
		graph_edit.add_child(graph_node)
		graph_node.size = Vector2(200.0, 0.0)
		graph_node.minimum_size = Vector2(200.0, 0.0)
		graph_node.visible = true
		graph_node.name = d_id
		graph_node.title = d_id
		graph_node.position_offset = pos
		graph_node.set_meta("port_index", 0)
		
		pos.y += 220
		if pos.y > 220 * 10:
			pos.y = 0
			pos.x += 220
		
		all_graph_nodes[d_id] = graph_node
		
		for flow_id in dialogue.flows:
			var flow: Dictionary = dialogue.flows[flow_id]
			var control := _new_line_button(graph_node, dialogue, flow, "=== %s" % flow_id, Color.TAN, HORIZONTAL_ALIGNMENT_LEFT)
			
			var rt := RichTextLabel.new()
			rt.set_text("Meta:")
			rt.fit_content_height = true
			rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
			control.add_child(rt)
			
			_add_slot(graph_node, Color.TAN, Color.TRANSPARENT)
			
			all_flow_buttons[[d_id, flow_id]] = control
			
			# go through all nested lines and create relevant buttons
			_process_lines(graph_node, dialogue, flow, "then")
	
	# connect everything up
	# - find => and == buttons
	# - find === they connect to
	# - connect_node()
	for g in goto_nodes:
		var p = Soot.split_path(g[0])
		var d_id = p[0]
		var flow = p[1]
		# if dialogue exists.
		if d_id in all_graph_nodes:
			var n: GraphNode = all_graph_nodes[d_id]
			var flow_node: Node = all_flow_buttons[[d_id, flow]]
			var goto_node: Node = g[1]
			var flow_name: String = flow_node.get_meta("graph_name")
			var goto_name: String = goto_node.get_meta("graph_name")
			var flow_index: int = flow_node.get_index()
			var goto_index: int = goto_node.get_index()
			graph_edit.connect_node(goto_name, goto_index, flow_name, flow_index)
	
#	for node in nodes.values():
#		node.selected = true
		
#	graph.arrange_nodes()
#	graph.hide()
#	graph.show()
	
#	for node in nodes.values():
#		node.selected = false
	
#	var rects := nodes.values().map(func(x): return x.get_global_rect())
#	var bound: Rect2 = rects[0]
#	for i in range(1, len(rects)):
#		bound = bound.merge(rects[i])
#	graph.scroll_offset = bound.position - bound.size

func _add_slot(graph_node: GraphNode, l: Color, r: Color):
	var port_index: int = graph_node.get_meta("port_index")
	graph_node.set_slot(port_index,
		true, -2 if l == Color.TRANSPARENT else 0, l,
		true, -1 if r == Color.TRANSPARENT else 0, r)
	graph_node.set_meta("port_index", port_index+1)

func _new_line_button(graph_node: GraphNode, dialogue: Dialogue, line: Dictionary,
	text: String, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_CENTER) -> Control:
	var btn := Button.new()
	btn.text = text
	btn.modulate = color
	btn.alignment = alignment
	btn.flat = true
	btn.pressed.connect(_pressed.bind(dialogue, line.M.file, line.M.line))
	btn.add_theme_font_override("font", font)
	var out: Control = btn
	
	match line.type:
		"flow":
			out = VBoxContainer.new()
			out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			out.add_child(btn)
	
	graph_node.add_child(out)
	out.set_meta("graph_name", graph_node.name)
	return out
	
func _process_lines(graph_node: GraphNode, dialogue: Dialogue, line: Dictionary, key: String):
	if key in line:
		for line_id in line[key]:
			_process_line(graph_node, dialogue, dialogue.lines[line_id])

func _process_line(graph_node: GraphNode, dialogue: Dialogue, line: Dictionary):
	match line.type:
		"text":
			_process_lines(graph_node, dialogue, line, "options")
		
		"option":
			_process_lines(graph_node, dialogue, line, "then")
		
		"end":
			_new_line_button(graph_node, dialogue, line, "><", Color.TOMATO)
		
		"goto", "call":
			var goto_path: String = line[line.type]
			var goto = Soot.split_path(goto_path)
			var d_id: String = goto[0]
			var flow: String = goto[1]
			var clr := Color.YELLOW_GREEN if line.type == "goto" else Color.DEEP_SKY_BLUE
			var text := flow if (d_id==dialogue.id) else goto_path + ("=>" if line.type == "goto" else "==")
			var button := _new_line_button(graph_node, dialogue, line, text, clr, HORIZONTAL_ALIGNMENT_RIGHT)
			
			# create ports
			_add_slot(graph_node, Color.TRANSPARENT, Color.GREEN_YELLOW)
			
			goto_nodes.append([goto_path, button])
		
		_:
			prints("Hmm", line.type, line)

func _pressed(dialogue: Dialogue, file: int, line: int):
	var path: String = dialogue.files[file]
	prints("Pressed: ", path, line)
	_select_and_edit(path, line)

func _select_and_edit(path: String, line: int):
	if is_plugin_hint:
		if File.new().file_exists(path):
			plugin.get_editor_interface().select_file(path)
			plugin.get_editor_interface().edit_resource.call_deferred(load(path))
			
			var code_edit: CodeEdit = plugin.get_code_edit(path)
			code_edit.set_caret_line(line)
