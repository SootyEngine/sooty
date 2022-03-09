extends Node
class_name FE_Files

const PATH_FILE := "res://addons/file_editor/ext_editor/%s_file.gd"

signal file_updated(file: FE_File)
signal files_updated()
signal extension_toggled()
signal settings_changed()

var EXTENSIONS := {
	"md": { name="MarkDown", start_hidden=false },
	"json": { name="JSON", start_hidden=false },
	"yaml": { name="YAML", start_hidden=false },
	"ini": { name="INI File", start_hidden=false },
	"cfg": { name="Config File", start_hidden=false },
	"soot": { name="Sooty Dialogue", start_hidden=false },
#	"rpy": { name="Ren'py Script", start_hidden=true },
	"txt": { name="Text File", start_hidden=true },
	"gd": { name="GDScript", start_hidden=true },
	"tres": { name="Text Resource", start_hidden=true },
	"csv": { name="Comma Seperated Values", start_hidden=true },
}

@export var show_dir_hidden := false
@export var show_dir_addons := false
@export var show_dir_empty := false
@export var show_dir_gdignore := false

@export var show_file_hidden := true
@export var show_file_extension := {}

func _ready() -> void:
	for e in EXTENSIONS:
		show_file_extension[e] = not EXTENSIONS[e].start_hidden
	
	open_dir.call_deferred("res://")
	open_dir.call_deferred("user://mods")

func set_setting(property: String, value):
	var last = FE_Util.get_nested(self, property)
	
	if last == value:
		return
	
	FE_Util.set_nested(self, property, value)
	
	if property.begins_with("show_dir_") or property.begins_with("show_file_"):
		set_process(true)
	
	settings_changed.emit()

func _process(_delta: float) -> void:
	for file in get_children():
		_refresh_dir(file)
	set_process(false)
	
func is_extension_enabled(ext: String) -> bool:
	return show_file_extension.get(ext, false)

func toggle_extension(ext: String):
	if ext in show_file_extension:
		show_file_extension[ext] = not show_file_extension[ext]
		extension_toggled.emit()
	else:
		print("No extension ", ext)

func is_visible(file: FE_BaseFile) -> bool:
	if file is FE_Directory:
		return _is_dir_visible(file)
	else:
		return _is_file_visible(file)

func _is_dir_visible(dir: FE_Directory) -> bool:
	var fname := dir.file_name
	
	if not show_dir_addons and fname == "addons":
		return false
	
	if not show_dir_hidden and fname.begins_with("."):
		return false
	
	if not show_dir_gdignore and dir.has_file(".gdignore"):
		return false
	
	if not show_dir_empty and _is_dir_empty(dir):
		return false
	
	return true

func _is_dir_empty(dir: FE_Directory) -> bool:
	for file in dir.get_children():
		if is_visible(file):
			return false
	return true

func _is_file_visible(file: FE_File) -> bool:
	var fname := file.file_name
	if not show_file_hidden and fname.begins_with("."):
		return false
	
	var ext := file.extension
	if not ext in show_file_extension or not show_file_extension[ext]:
		return false

	return true

func has_file(path: String) -> bool:
	for file in get_children():
		if file.path == path:
			return true
	return false

func open_dir(path: String):
	if not has_file(path):
		_add_file(self, path, true)

func _refresh_dir(d: FE_Directory):
	var dir := Directory.new()
	var err := dir.open(d.path)
	if err != OK:
		push_error("Can't open dir %s: %s" % [d.path, err])
	
	else:
		var old_files := d.get_files()
		var new_files := {}
		
		# scan files
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname:
			var path := d.path.plus_file(fname)
			
			if dir.current_is_dir():
#				if is_dir_allowed(fname, path):
				new_files[path] = true
			else:
#				if is_file_allowed(fname):
				if fname.get_extension() in EXTENSIONS:
					new_files[path] = false
			
			fname = dir.get_next()
		
		# check for files removed
		for path in old_files:
			if not path in new_files:
#				print("removed ", path)
				var file = old_files[path]
				d.remove_child(file)
				file.queue_free()
		
		# check for files added
		for path in new_files:
			if not path in old_files:
#				print("added ", path)
				_add_file(d, path, new_files[path])
		
#		print(JSON.new().stringify(d.get_json(), "\t", false))

func _add_file(parent: Node, path: String, is_dir: bool):
	var file: FE_BaseFile
	if is_dir:
		file = FE_Directory.new(path)
	else:
		var extension := path.get_file().split(".", true, 1)[-1]
		var script_path := PATH_FILE % extension
		if File.new().file_exists(script_path):
			file = load(script_path).new(path)
		else:
			file = FE_File.new(path)
	file.modified.connect(_file_modified.bind(file))
	parent.add_child(file)
	_file_modified.call_deferred(file)

func _file_modified(file: FE_BaseFile):
	if file is FE_Directory:
		_refresh_dir(file)
	file_updated.emit(file)
	files_updated.emit()
