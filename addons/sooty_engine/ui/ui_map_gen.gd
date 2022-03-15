extends Node

var prefab: GraphNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_deferred.call_deferred()
	prefab = $GraphEdit/prefab
	prefab.visible = false
	
func _ready_deferred():
	var nodes := {}
	var pos := Vector2.ZERO
	
	for did in Dialogues.cache:
		var d: Dialogue = Dialogues.cache[did]
		for fid in d.flows:
			var id = "%s.%s" % [did, fid]
			var p: GraphNode = prefab.duplicate()
			$GraphEdit.add_child(p)
			p.name = id
			p.visible = true
			p.title = id
			p.position_offset = pos
			pos.y += 220
			if pos.y > 220 * 10:
				pos.y = 0
				pos.x += 220
			var a := []
			for line in d.lines.values():
				if line.type == "goto":
					a.append(line.goto)
			print(id)
			nodes[id] = {node=p, connections=a}
	
	var ge: GraphEdit = $GraphEdit
	for c in nodes:
		var v = nodes[c]
		var n: GraphNode = v.node
		for c2 in v.connections:
			if c == c2:
				continue
			if c2 in nodes:
				var n2: GraphNode = nodes[c2].node
				ge.connect_node(n.name, 0, n2.name, 1)
			else:
				push_error("No node %s." % c2)

	
#	for node in nodes.values():
#		var n: Dialogue
