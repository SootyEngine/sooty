extends Node

var prefab: GraphNode

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
	
	for did in Dialogues.cache:
		var d: Dialogue = Dialogues.cache[did]
		var node: GraphNode = prefab.duplicate()
		graph.add_child(node)
		node.rect_size = Vector2.ZERO
		node.rect_min_size = Vector2.ZERO
		node.visible = true
		node.name = did
		node.title = did
		node.position_offset = pos
		pos.y += 220
		if pos.y > 220 * 10:
			pos.y = 0
			pos.x += 220
		
		nodes[did] = node
		
		for flow_id in d.flows:
			var flow_label := Label.new()
			node.add_child(flow_label)
			flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			flow_label.text = flow_id
			flow_label.modulate = Color.DEEP_SKY_BLUE
			
			var f_index := node.get_child_count()-1
			node.set_slot_enabled_left(f_index, true)
			node.set_slot_color_left(f_index, flow_label.modulate)
			node.set_meta(flow_id, f_index)
			
			for k in d.flows[flow_id].then:
				var line = d.lines[k]
				match line.type:
					"goto":
						var goto_label := Label.new()
						node.add_child(goto_label)
						goto_label.text = line.goto
						goto_label.modulate = Color(.25, .25, .25, 1.0)
						goto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
						
						var goto_index := node.get_child_count()-1
						node.set_slot_enabled_right(goto_index, true)
						node.set_slot_color_right(goto_index, goto_label.modulate)
						gotos.append([did, goto_index, line.goto])
	
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
