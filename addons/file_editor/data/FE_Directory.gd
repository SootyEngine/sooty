@tool
extends FE_BaseFile
class_name FE_Directory

@export var tint := Color.WHITE

func _ready() -> void:
	open_in_file_list = true

func get_popup_options() -> Array:
	return [
		{text="New File"},
		{type="---"},
		{text="Remove"},
		{type="---"},
		{text="Tint/Yellow"},
		{text="Tint/Red"},
		{text="Tint/Blue"},
		{text="Tint/Green"},
		
		{text="Sort/Name A-Z"},
		{text="Sort/Name Z-A"},
		{text="Sort/Size <"},
		{text="Sort/Size >"},
	]

func is_empty() -> bool:
	for file in get_children():
		if file is FE_Directory:
			if not file.is_empty():
				return false
		elif file is FE_File:
			return false
	return true

func has_file(fname: String) -> bool:
	return File.new().file_exists(path.plus_file(fname))

func get_json() -> Dictionary:
	var out := { path=path }
	out.files = {}
	for child in get_children():
		out.files[child.path] = child.get_json()
	return out

func get_files() -> Dictionary:
	var out := {}
	for child in get_children():
		out[child.path] = child
	return out

func get_file(path: String) -> Node:
	for i in get_child_count():
		var child := get_child(i)
		if child.path == path:
			return child
	return null

func sort():
	var dirs := []
	var files := []
	for file in get_children():
		if file is FE_Directory:
			dirs.append(file)
		else:
			files.append(file)
	dirs.sort_custom(func(a, b): return a.file_name < b.file_name)
	files.sort_custom(func(a, b): return a.file_name < b.file_name)
	var all := dirs + files
	for i in len(all):
		move_child(all[i], i)
