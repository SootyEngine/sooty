extends FE_BaseFile
class_name FE_File

var extension: String:
	get: return path.get_file().split(".", true, 1)[-1]

var chapters := {}
var tags := {}

func reload():
	super.reload()
	parse(load_text())
	emit_signal("modified")

func parse(text: String):
	chapters.clear()
	tags.clear()
	_parse(text.split("\n"))

func _parse(lines: PackedStringArray):
	pass

func _add_chapter(line: int, name: String, deep: int=0):
	chapters[line] = { name=name, deep=deep }

func is_open() -> bool:
	return get_editor() != null

func is_current() -> bool:
	var tab := get_editor()
	return tab != null and tab.is_current()

func remove_temp():
	for child in editors.get_children():
		if child.opened_but_not_edited:
			editors.remove_child(child)
			child.queue_free()
			return

func load_text() -> String:
	return FE_Util.load_text(path)

func get_editor() -> Node:
	return editors.get_editor(self)

func find_chapter_line(id: String) -> int:
	for line in chapters:
		if chapters[line].name == id:
			return line
	return -1

func get_errors(text: String) -> Array:
	return []

var errors := []

func save(text: String) -> bool:
	errors = get_errors(text)
	
	if len(errors):
		return false
	
	if FE_Util.save_text(path, text):
		reload()
		return true
	
	else:
		push_error("Failed saving %s." % path)
		return false

func open(line: int=-1):
	var tab := editors.open(self)
	tab.goto(line)
#	var tab := get_editor_tab()
#
#	if tab:
#		tab.opened_but_not_edited = false
#
#	remove_temp()
#
#	if not tab:
#		tab = _create_editor()
#		if not tab:
#			return
#
#	editors.set_current_tab(tab.get_index())
#	tab.goto(line)
#	reload()

func rename(new_path: String):
	if path == new_path or path == "" or new_path == "":
		push_error("Can't rename '%s' to '%s'." % [path, new_path])
		return
	
	if new_path.get_base_dir() != path.get_base_dir():
		push_error("Don't use rename() to move files.")
		return
	
	if File.new().file_exists(new_path):
		var err_msg = "Can't rename '%s' to '%s'. File already exists." % [path, new_path]
		push_error(err_msg)
		return
	
	var was_current = is_current()
	if Directory.new().rename(path, new_path) == OK:
		var old_path := path
		path = new_path
#		file_data[new_path] = file_data[old_path]
#		file_data.erase(old_path)
#		refresh_files()
		emit_signal("modified")
#		if is_current:
#			pass
#			_selected_file_changed(new_path)
	
	else:
		var err_msg = "Couldn't rename '%s' to '%s'." % [path, new_path]
		push_error(err_msg)
