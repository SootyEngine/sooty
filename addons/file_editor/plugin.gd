@tool
extends EditorPlugin

const TEPanel: PackedScene = preload("res://addons/file_editor/file_editor.tscn")
var panel: FE_Main

func _enter_tree() -> void:
	panel = TEPanel.instantiate()
	panel._set_as_plugin()
	get_editor_interface().get_editor_main_control().add_child(panel)
	_make_visible(false)
	
#	get_editor_interface().get_script_editor().editor_script_changed.connect(_script_changed)

func _exit_tree() -> void:

	if panel:
		panel.queue_free()
#
func _get_plugin_name() -> String:
	return "Text"

func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("TextFile", "EditorIcons")

func  _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if panel:
		panel.visible = visible
