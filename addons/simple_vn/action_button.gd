extends Button

@export_multiline var command := ""

func _init() -> void:
	DialogueStack.started.connect(set_disabled.bind(true))
	DialogueStack.finished.connect(set_disabled.bind(false))

func _pressed() -> void:
	if command.begins_with(Sooty.S_FLOW_GOTO):
		var goto := command.trim_prefix(Sooty.S_FLOW_GOTO).strip_edges()
		DialogueStack.goto(goto, DialogueStack.STEP_GOTO)
	elif command.begins_with(Sooty.S_FLOW_CALL):
		var call := command.trim_prefix(Sooty.S_FLOW_CALL).strip_edges()
		DialogueStack.goto(call, DialogueStack.STEP_CALL)
	else:
		State.do(command)
	
	release_focus()
