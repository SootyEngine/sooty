#@tool
#extends Node
#
#const WAIT_TIME := 1.0
#
#@export var times := {}
#@export var wait := WAIT_TIME
#
#func _ready() -> void:
#	if not Engine.is_editor_hint():
#		set_process(false)
#
#func _process(delta: float) -> void:
#	wait -= delta
#	if wait <= 0.0:
#		wait = WAIT_TIME
#		_rebuild()
#
#func _rebuild():
#	var files := UFile.get_files("res://state", "gd")
#	var needs_update := false
#	var new_times := {}
#
#	if len(files) != len(times):
#		needs_update = true
#
#	for file in files:
#		new_times[file] = UFile.get_modified_time(file)
#		if new_times[file] != times.get(file, 0):
#			needs_update = true
#
#	times = new_times
#
#	if not needs_update:
#		return
#
#	var lines := []
#	lines.append("# WARNING: Auto generated script. Modifications will be overwritten.")
#	lines.append("@tool")
#	lines.append("extends GameStateBase")
##	lines.append("class_name State")
#	for file in files:
#		var id := file.get_basename().trim_prefix("res://state/")
#		if id.begins_with("_"):
#			var text := UFile.load_text(file).split("\n", false)
#			text.remove_at(0) # Ignore 'extends x' line.
#			lines.append_array(text)
#		else:
#			var cp := id.capitalize().replace(" ", "")
#			lines.append("const %s = preload(\"%s\")" % [cp, file])
#			lines.append("var %s:%s = %s.new()" % [id, cp, cp])
#	var final := "\n".join(lines)
#	# print(final)
#	UFile.save_text("res://state.gd", final)
#	print("Rebuilt state.gd.")
