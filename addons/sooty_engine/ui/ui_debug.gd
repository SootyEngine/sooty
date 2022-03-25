extends Node

var lines := []
var filter := ""
var persistent := false
var only_modified := true

func _ready() -> void:
	$VBoxContainer/HBoxContainer/persistent.toggled.connect(_toggle_persistent)
	$VBoxContainer/HBoxContainer/force_update.pressed.connect(_update)
	$VBoxContainer/HBoxContainer/only_modified.toggled.connect(_toggle_only_modified)
	$VBoxContainer/HBoxContainer/filter.text_changed.connect(_filter_changed)
	State.changed.connect(_changed)
	Persistent.changed.connect(_changed)

func _toggle_persistent(t):
	persistent = t
	_update()

func _toggle_only_modified(t):
	only_modified = t
	_update()

func _changed(_property):
	_update()

func _filter_changed(t: String):
	filter = t
	_redraw()

func _update():
	var node = Persistent if persistent else State
	var state := node._get_changed_states() if only_modified else node._get_state()
	lines = JSON.new().stringify(state, "\t", false).split("\n")
	for i in len(lines):
		if ":" in lines[i]:
			var p = lines[i].split(":", true, 1)
			p[0] = p[0].replace('"', "")
			p[1] = UString.unwrap(p[1].strip_edges().trim_suffix(","), '"')
			lines[i] = "[dim]%s[dim]:[/] %s" % [p[0], p[1]]
	_redraw()

func _redraw():
	var text = []
	for line in lines:
		if filter == "" or filter in line.to_lower():
			text.append(line)
	$VBoxContainer/output.set_bbcode("\n".join(text))
