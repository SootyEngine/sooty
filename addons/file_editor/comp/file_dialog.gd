extends FileDialog

var FILTERS: PackedStringArray

func _ready() -> void:
	var fm: FE_Files = get_tree().get_first_node_in_group("fe_files")
	var a := []
	for e in fm.EXTENSIONS:
		a.append("*.%s ; %s" % [e, fm.EXTENSIONS[e].name])
	FILTERS = PackedStringArray(a)

func set_folder(args=null):
	set_filters(FILTERS)
	set_access(FileDialog.ACCESS_RESOURCES)
	set_current_dir("res://")
	set_size(get_viewport().size * .8)
	set_position((get_viewport().size - size) * 0.5)
	
	match "dir":
		"dir":
			set_file_mode(FileDialog.FILE_MODE_OPEN_DIR)
			dir_selected.connect(_open_dir, CONNECT_ONESHOT)
		
		"open_file":
			set_file_mode(FileDialog.FILE_MODE_OPEN_FILE)
			file_selected.connect(_file_selected, CONNECT_ONESHOT)
		
		"save_file":
			set_file_mode(FileDialog.FILE_MODE_SAVE_FILE)
			file_selected.connect(_file_selected, CONNECT_ONESHOT)
	
	show()

func _open_dir(path: String):
	pass

func _file_selected(path: String):
	pass
