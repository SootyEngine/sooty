#extends SootStack
#class_name DStack
#
#func _ready():
#	if not Engine.is_editor_hint():
#		await Global.get_tree().process_frame
#		Saver._get_state.connect(_save_state)
#		Saver._set_state.connect(_load_state)
#		self.reloaded.connect(_dialogues_reloaded)
#
#func _save_state(state: Dictionary):
#	state["DS"] = _get_state()
#
#func _load_state(state: Dictionary):
#	_set_state(state["DS"])
#
#func _dialogues_reloaded():
##	_refresh.emit()
#	_waiting_for.clear()
#	waiting_list_changed.emit()
#	_stack = _last_tick_stack.duplicate(true)
#
#func _process(_delta: float) -> void:
#	_tick()
#
#func _get_step(id: String) -> Dictionary:
#	return Dialogues._lines[id]
#
#func _has_step(id: String) -> bool:
#	if not Soot.is_path(id):
#		push_error("Missing part of flow path: '%s'." % id)
#		return false
#
#	var p := Soot.split_path(id)
#	var d_id := p[0]
#	var flow := p[1]
#	# dialogue exists?
#	var d: Dialogue = Dialogues.find(d_id)
#	if not d:
#		return false
#
#	# flow exists?
#	var f: Dictionary = d.find(flow)
#	if not len(f):
#		return false
#
#	var lines := d.get_flow_lines(flow)
#	if not len(lines):
#		push_error("Can't find lines for '%s'." % flow)
#		return false
#
#	return true
