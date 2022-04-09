@tool
class_name UFile

const EXT_IMAGE := [".png", ".jpg", ".jpeg", ".webp"]
const EXT_AUDIO := [".mp3", ".wav", ".ogg"]

static func get_user_dir() -> String:
	if not OS.is_debug_build():
		var dir = OS.get_executable_path().get_base_dir()
		if file_exists(dir + "/_sc_") or file_exists(dir + "/._sc_"):
			return dir + "/data/"
	return "user://"

# Check if anything exists at this path.
static func exists(path: String) -> bool:
	var d := Directory.new()
	return d.file_exists(path) or d.dir_exists(path)

# Check if file exists at this path.
static func file_exists(path: String) -> bool:
	return File.new().file_exists(path)

# Check if file exists in directory or one of it's sub directories.
static func file_exists_in_dir(dir: String, tail: String) -> bool:
	return len(get_files(dir, tail, true, false, 1)) > 0

# Get a file ending in tail, in this directory or one of it's sub directories.
static func get_file_in_dir(dir: String, tail: String) -> String:
	var paths := get_files(dir, tail, true, false, 1)
	return "" if len(paths) == 0 else paths[0]

# Check if directory exists at this path.
static func dir_exists(path: String) -> bool:
	return Directory.new().dir_exists(path)

# Time this file was modified at.
static func get_modified_time(path: String) -> int:
	return File.new().get_modified_time(path)

static func get_file_size_humanized(path: String) -> String:
	return String.humanize_size(get_file_size(path))

# Size of file, in bytes, at this location.
static func get_file_size(path: String) -> int:
	var f := File.new()
	var _e = f.open(path, File.READ)
	f.seek_end()
	var bytes = f.get_position()
	f.close()
	return bytes

# Hacky.
# Size of all the files in a directory, added up together.
static func get_directory_size(directory: String) -> String:
	var bytes := 0
	for path in get_files(directory, null, true, true):
		bytes += get_file_size(path)
	return String.humanize_size(bytes)

static func get_file_name(path: String) -> String:
	return path.get_file().split(".", true, 1)[0]


#static func get_directory_name(path:String) -> String:
#	var head = null
#
#	if path.begins_with("res://"):
#		head = "res://"
#		path = path.substr(6)
#
#	elif path.begins_with("user://"):
#		head = "user://"
#		path = path.substr(7)
#
#	if "/" in path:
#		path = path.rsplit("/", true, 1)[0]
#
#	elif "." in path:
#		path = path.rsplit(".", true, 1)[0]
#
#	if head:
#		return head + path
#
#	else:
#		return path

static func change_extension(path: String, ext: String) -> String:
	var parts := path.rsplit("/", true, 1)
	var fpath := parts[0]
	var fname := parts[1].split(".", true, 1)[0]
	return "%s/%s.%s" % [fpath, fname, ext]

static func change_name(path: String, new_name: String) -> String:
	var parts := path.rsplit("/", true, 1)
	var fpath := parts[0]
	var fparts := parts[1].split(".", true, 1)
	var old_name := fparts[0]
	var old_ext := fparts[1]
	return "%s/%s.%s" % [fpath, new_name, old_ext]

static func create_dir(path: String) -> bool:
	var dir = get_user_dir()
	if path != dir and path.begins_with(dir):
		var d := Directory.new()
		if d.dir_exists(path):
			return true
		elif not UError.error(d.make_dir_recursive(path), "creating directory '%s'" % dir):
			return true
	push_error("Cant make dir '%s'." % path)
	return false

static func remove_dir(path: String) -> bool:
	var d := Directory.new()
	if path != "user://" and path.begins_with("user://") and d.dir_exists(path):
		
		for file in get_files(path):
			d.remove(file)
		
		if not UError.error(d.remove(path), "Can't remove directory '%s'." % path):
			return true
	
	return false

static func save_node(path: String, node: Node) -> bool:
	var packed := PackedScene.new()
	if not UError.error(packed.pack(node), "Can't save '%s'." % path):
		if not UError.error(ResourceSaver.save(path, packed, ResourceSaver.FLAG_COMPRESS), "Can't save '%s'." % path):
			return true
	return false

# allows loading external assets if in "user://"
static func load2(path: String, default = null) -> Variant:
	if path.begins_with(get_user_dir()):
		var ext = "." + path.get_extension().to_lower()
		if ext in EXT_IMAGE:
			return load_image(path, default) 
		elif ext in EXT_AUDIO:
			return load_audio(path, default)
		else:
			push_error("No external loader for '%s' at '%s'." % [ext, path])
			return default
	else:
		return load(path)

static func save_image(path:String, image:Image) -> bool:
	var f := File.new()
	if not UError.error(f.open(path, File.WRITE), "Can't open '%s'." % path):
		f.store_buffer(image.save_png_to_buffer())
		f.close()
		return true
	return false

static func load_image(path: String, default = null) -> ImageTexture:
	if file_exists(path):
		var image := Image.new()
		image.load(path)
		var texture := ImageTexture.new()
		texture.create_from_image(image)
		return texture
	push_error("No image at %s" % path)
	return default

static func load_audio(path: String, default = null) -> AudioStream:
	var f := File.new()
	if f.file_exists(path):
		var aud:AudioStream
		match path.get_extension():
			"mp3": aud = AudioStreamMP3.new()
			"wav": aud = AudioStreamSample.new()
			"ogg": aud = AudioStreamOGGVorbis.new()
		f.open(path, File.READ)
		aud.data = f.get_buffer(f.get_len())
		f.close()
		return aud
	return default

# Like JSON, but full serialization support.
static func save_to_resource(path: String, data = null) -> bool:
	var res := Resource.new()
	res.set_meta("data", data)
	return not UError.error(ResourceSaver.save(path, res, ResourceSaver.FLAG_COMPRESS), "Can't save to '%s'." % path)

static func load_from_resource(path: String, default: Variant = null) -> Variant:
	var f := File.new()
	if f.file_exists(path):
		var res: Resource = load(path)
		return res.get_meta("data", default)
	return default

static func load_json(path: String, default = null) -> Variant:
	var f := File.new()
	if f.file_exists(path):
		if not UError.error(f.open(path, File.READ), "Can't open '%s'." % path):
			var json := JSON.new()
			var text := f.get_as_text()
			f.close()
			if not UError.error(json.parse(text), "Can't parse JSON at '%s'." % path):
				return json.get_data()
	return default

static func save_json(path: String, data: Variant, tabs: bool = false) -> bool:
	if not path.begins_with("res://") and not path.begins_with(get_user_dir()):
		return false
	
	var f := File.new()
	if not UError.error(f.open(path, File.WRITE), "Can't open '%s'." % path):
		if tabs:
			f.store_string(JSON.new().stringify(data, "\t", false))
		else:
			f.store_string(JSON.new().stringify(data, "", false))
		f.close()
		return true
	
	return false

static func load_text(path: String) -> String:
	var f := File.new()
	if f.file_exists(path):
		if not UError.error(f.open(path, File.READ), "Can't open '%s'." % path):
			var text = f.get_as_text()
			f.close()
			return text
	return ""

static func save_text(path: String, text: String) -> bool:
	var f := File.new()
	f.open(path, File.WRITE)
	f.store_string(text)
	f.close()
	return true

# Call's 'call' on every file.
static func scan_dir(path:String, call: Callable, nested: bool = true, hidden: bool = false):
	var dir := Directory.new()
	dir.include_hidden = hidden
	if dir.open(path) == OK:
		_scan_dir(dir, call, nested)
	else:
		push_error("An error occurred when trying to access the path.")

static func _scan_dir(dir:Directory, call: Callable, nested:bool):
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		var path = dir.get_current_dir().plus_file(fname)
		if dir.current_is_dir():
			# ignore folders with a .gdignore file.
			if nested and not fname == ".import" and not File.new().file_exists(path.plus_file(".gdignore")):
				var sub_dir = Directory.new()
				sub_dir.open(path)
				_scan_dir(sub_dir, call, nested)
		else:
			# ignore .import files
			if not path.ends_with(".import"):
				call.call(path)
		fname = dir.get_next()
	dir.list_dir_end()

static func get_dirs(paths, nested: bool = false, hidden: bool = false) -> PackedStringArray:
	var out := []
	var dir := Directory.new()
	dir.include_hidden = hidden
	
	for path in UList.list(paths):
		if dir.dir_exists(path) and not UError.error(dir.open(path), "Can't open '%s'." % path):
			_get_dirs(dir, out, nested)
	
	return PackedStringArray(out)

static func _get_dirs(dir: Directory, out: Array, nested: bool):
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if dir.current_is_dir():
			var path = dir.get_current_dir().plus_file(fname)
			out.append(path)
			# ignore folders with a .gdignore file.
			if nested and not file_exists(path.plus_file(".gdignore")):
				var sub_dir = Directory.new()
				sub_dir.open(path)
				_get_dirs(sub_dir, out, true)
		fname = dir.get_next()
	dir.list_dir_end()

# Calls a function on every file in the given directories, with the given extensions.
# paths can be a string or an array of strings.
static func on_files(paths: Variant, call: Callable, extensions: Variant = [], nested := true, hidden := false, maximum := 1_000_000_000):
	var dir := Directory.new()
	dir.include_hidden = hidden
	var exts := UList.list(extensions)
	for path in UList.list(paths):
		if dir.dir_exists(path) and not UError.error(dir.open(path), "Can't open '%s'." % path):
			maximum = _on_files(dir, call, exts, nested, hidden, maximum)
			if maximum <= 0:
				return

static func _on_files(dir: Directory, call: Callable, extensions: Variant, nested: bool, hidden: bool, maximum: int) -> int:
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		var path = dir.get_current_dir().plus_file(fname)
		if dir.current_is_dir():
			# ignore .import and folders with a .gdignore file.
			if nested and not fname == ".import" and not file_exists(path.plus_file(".gdignore")):
				var sub_dir = Directory.new()
				sub_dir.include_hidden = hidden
				sub_dir.open(path)
				maximum = _on_files(sub_dir, call, extensions, nested, hidden, maximum)
		
		elif not len(extensions) or _ends_with(fname, extensions):
			call.call(path)
			maximum -= 1
		
		if maximum <= 0:
			break
		
		fname = dir.get_next()
	dir.list_dir_end()
	return maximum

static func get_files(paths: Variant, extensions: Variant = [], nested := true, hidden := false, maximum := 1_000_000_000) -> PackedStringArray:
	var out := []
	on_files(paths, func(x): out.append(x), extensions, nested, hidden, maximum)
	return PackedStringArray(out)

#	var out := []
#	var dir := Directory.new()
#	dir.include_hidden = hidden
#
#	var exts := UList.list(extensions)
#
#	for path in UList.list(paths):
#		if dir.dir_exists(path) and not UError.error(dir.open(path), "Can't open '%s'." % path):
#			_get_files(dir, out, exts, nested, maximum)
#
#	return PackedStringArray(out)

#static func _get_files(dir: Directory, extensions: Array, out: Array, nested: bool, maximum: int):
#	dir.list_dir_begin()
#	var fname = dir.get_next()
#	while fname != "":
#		var path = dir.get_current_dir().plus_file(fname)
#		if dir.current_is_dir():
#			# ignore .import and folders with a .gdignore file.
#			if nested and not fname == ".import" and not file_exists(path.plus_file(".gdignore")):
#				var sub_dir = Directory.new()
#				sub_dir.open(path)
#				_get_files(sub_dir, out, extensions, true, maximum)
#
#		elif not len(extensions) or _ends_with(fname, extensions):
#			# html5 export hack
##			if path.ends_with(".import"):
##				path = path.substr(0, len(path)-7)
##
##			elif path.ends_with(".remap"):
##				path = path.substr(0, len(path)-6)
#
#			out.append(path)
#			if maximum != -1 and len(out) >= maximum:
#				break
#
#		elif len(extensions) and ".gd" in extensions:
#			if not OS.is_debug_build():
#				push_error("?? " + path)
#
#		fname = dir.get_next()
#	dir.list_dir_end()

static func _ends_with(s: String, endings: Array) -> bool:
	for ending in endings:
		if s.ends_with(ending):
			return true
	
	# html5 export hack
#	for ending in endings:
#		if s.ends_with(ending + ".import") or s.ends_with(".remap"):
#			return true
	
	return false
