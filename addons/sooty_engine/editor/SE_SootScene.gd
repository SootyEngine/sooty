extends EditorInspectorPlugin

func _can_handle(object) -> bool:
	return object is SootScene
