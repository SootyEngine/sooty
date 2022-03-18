extends Node

var prefab: GraphNode
@export var font: Font

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_deferred.call_deferred()
	prefab = $GraphEdit/prefab
	prefab.visible = false
	
func _ready_deferred():
	var nodes := {}
	var gotos := []
	var pos := Vector2.ZERO
	var graph: GraphEdit = $GraphEdit
	var clr_gray := Color(.33, .33, .33, 1.0)
	
	for dialogue_id in Dialogues.cache:
		var d: Dialogue = Dialogues.cache[dialogue_id]
		var node: GraphNode = prefab.duplicate()
		graph.add_child(node)
		node.rect_size = Vector2(200.0, 0.0)
		node.rect_min_size = Vector2(200.0, 0.0)
		node.visible = true
		node.name = dialogue_id
		node.title = dialogue_id
		node.position_offset = pos
		pos.y += 220
		if pos.y > 220 * 10:
			pos.y = 0
			pos.x += 220
		
		nodes[dialogue_id] = node
		var slot_index := 0
		
		for flow_id in d.flows:
			var flow_line: Dictionary = d.flows[flow_id]
			var flow_label := Button.new()
			flow_label.add_theme_font_override("font", font)
			node.add_child(flow_label)
			flow_label.flat = true
			flow_label.text = "⦗%s⦘" % flow_id
			flow_label.modulate = Color.WHITE
			flow_label.alignment = HORIZONTAL_ALIGNMENT_LEFT
			flow_label.pressed.connect(_pressed.bind(d, flow_line.file, flow_line.line))
			
			node.set_slot_enabled_left(slot_index, true)
			node.set_slot_color_left(slot_index, clr_gray)
			node.set_meta(flow_id, slot_index)
			slot_index += 1
			
			for k in flow_line.then:
				var line = d.lines[k]
				match line.type:
					"goto", "call":
						var goto = line[line.type].split(".", true, 1)
						var goto_dialogue: String = goto[0]
						var goto_flow: String = goto[1]
						var goto_label := Button.new()
						var clr := Color.YELLOW_GREEN if line.type == "goto" else Color.DEEP_SKY_BLUE
						if goto_dialogue == dialogue_id:
							clr = flow_label.modulate
						node.add_child(goto_label)
						goto_label.flat = true
						goto_label.text = goto_dialogue + (" >" if line.type == "goto" else " =")
						goto_label.modulate = Color(clr, .5)
						goto_label.alignment = HORIZONTAL_ALIGNMENT_RIGHT
						goto_label.pressed.connect(_pressed.bind(d, line.file, line.line))
						
						node.set_slot_enabled_right(slot_index, true)
						node.set_slot_color_right(slot_index, clr)
						gotos.append([dialogue_id, slot_index, line[line.type]])
						slot_index += 1
		
		node.move_child(node.get_child(0), node.get_child_count())
	
	for g in gotos:
		var dialogue_from: String = g[0]
		var goto_index: int = g[1]
		var goto: String = g[2]
		var p := goto.split(".", true, 1)
		var dialogue_to := p[0]
		var goto_flow := p[1]
		if dialogue_to in nodes and dialogue_to != dialogue_from:
			var n: GraphNode = nodes[dialogue_to]
			if n.has_meta(goto_flow):
				var flow_index: int = n.get_meta(goto_flow)
				graph.connect_node(dialogue_from, goto_index-1, dialogue_to, flow_index)
	
	for node in nodes.values():
		node.selected = true
		
	graph.arrange_nodes()
	graph.hide()
	graph.show()
	
	for node in nodes.values():
		node.selected = false
	
	var rects := nodes.values().map(func(x): return x.get_global_rect())
	var bound: Rect2 = rects[0]
	for i in range(1, len(rects)):
		bound = bound.merge(rects[i])
	graph.scroll_offset = bound.position - bound.size

func _pressed(dialogue: Dialogue, file: int, line: int):
	prints("Pressed: ", dialogue.files.keys()[file], line)
