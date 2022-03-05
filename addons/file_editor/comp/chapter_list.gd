extends "res://addons/file_editor/comp/base_filtered_list.gd"

func _ready() -> void:
	super._ready()
	msg_no_items = "No items"
	
	var f: FE_Files = get_tree().get_first_node_in_group("fe_files")
	f.file_updated.connect(_file_updated)
	
	var e: FE_Editors = get_tree().get_first_node_in_group("fe_editors")
	e.current_editor_changed.connect(_editor_changed)

func _clicked(meta: Variant):
	meta[0].open(meta[1])

func _editor_changed():
	# TODO
	if not is_inside_tree():
		return
	var editor: FE_Editors = get_tree().get_first_node_in_group("fe_editors")
	_redraw(editor.get_current_file())

func _file_updated(file: FE_BaseFile):
	if file is FE_File and file.is_current():
		_redraw(file)

func _redraw(file: FE_File):
	items.clear()
	if file != null:
		for line in file.chapters:
			var chapter: Dictionary = file.chapters[line]
			items.append({ text=chapter.name, meta=[file, line], deep=chapter.deep })
	items_updated()
