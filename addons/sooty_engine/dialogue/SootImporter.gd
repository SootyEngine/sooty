@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "soot_script.plugin"

func _get_visible_name() -> String:
	return "Soot"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["soot"])

func _get_save_extension() -> String:
	return "tres"

func _get_resource_type() -> String:
	return "Resource"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array:
	return [{"name": "my_option", "default_value": false }]

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	var file := File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED
	
	var soot := Soot.new()
	soot.text = file.get_as_text()
	file.close()
	# Fill the Mesh with data read in "file", left as an exercise to the reader.
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(filename, soot)
