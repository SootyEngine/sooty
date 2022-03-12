@tool
extends "res://addons/file_editor/comp/base_filtered_list.gd"

func _ready() -> void:
	super._ready()
	msg_no_items = "No items"
	_ready_deferred.call_deferred()

func _ready_deferred():
	files.file_updated.connect(_file_updated)
	editors.current_editor_changed.connect(_editor_changed)

func _clicked(meta: Variant):
	meta[0].open(meta[1])

func _editor_changed():
	# TODO
	if not is_inside_tree():
		return
	_redraw(editors.get_current_file())

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
