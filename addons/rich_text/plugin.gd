@tool
extends EditorPlugin

func _enter_tree() -> void:
	var se: ScriptEditor = get_editor_interface().get_script_editor()

func _exit_tree() -> void:
	pass
