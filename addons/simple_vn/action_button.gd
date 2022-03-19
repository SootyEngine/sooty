extends Button

@export_multiline var command := ""

func _pressed() -> void:
	State.do(command)
	release_focus()
