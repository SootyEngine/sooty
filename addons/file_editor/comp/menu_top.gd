@tool
extends Control

@export_node_path(Label) var _l_version:NodePath
@onready var l_version: Label = get_node(_l_version)

func _ready() -> void:
	_init_version.call_deferred()
	_init_popups.call_deferred()

func _init_version():
	var main: FE_Main = owner
	var is_plugin := main.is_plugin_hint()
	var path := "res://addons/file_editor/plugin.cfg"
	var conf := FE_Util.load_cfg(path)
	if is_plugin:
		l_version.set_text("P v%s" % conf.get_value("plugin", "version", "?.?"))
	else:
		l_version.set_text("v%s" % conf.get_value("plugin", "version", "?.?"))

func _init_popups():
	var file_dialog: FileDialog = owner.file_dialogue
	var f: PopupMenu = $file.get_popup()
	f.clear()
	f.set_script(FE_OptionsMenu)
	f.add_options([
		{ text="Set Folder", call=file_dialog.set_folder },
		{ text="Add Folder", call=file_dialog.set_folder },
	])
	
	var e: PopupMenu = $edit.get_popup()
	e.clear()
	e.set_script(FE_OptionsMenu)
	e.add_options([
		{ text="Undo", shortcut="ctrl+z" },
		{ text="Redo", shortcut="ctrl+shift+z" },
		{ text="Zoom", shortcut="ctrl+plus" },
		{ text="Unzoom", shortcut="ctrl+minus" },
	])
	
	var files: FE_Files = owner.files
	
	var v: PopupMenu = $view.get_popup()
	v.clear()
	v.set_script(FE_OptionsMenu)
	v.add_options([
		{ text="Directories/Empty", call=func(x): files.set_setting("show_dir_empty", x), check=files.get.bind("show_dir_empty") },
		{ text="Directories/Hidden", call=func(x): files.set_setting("show_dir_hidden", x), check=files.get.bind("show_dir_hidden") },
		{ text="Directories/Addons", call=func(x): files.set_setting("show_dir_addons", x), check=files.get.bind("show_dir_addons") },
		{ text="Directories/.gdignore", call=func(x): files.set_setting("show_dir_gdignore", x), check=files.get.bind("show_dir_gdignore") },
	])
	# add file button for each extension
	for ext in files.EXTENSIONS:
		v.add_option({
			text="Files/.%s (%s)" % [ext, files.EXTENSIONS[ext].name],
			call=func(x): files.set_setting("show_file_extension." + ext, x),
			check=files.is_extension_enabled.bind(ext),
		})
	
	# update checkboxes whenever a extensions visibility is toggled
#	files.extension_toggled.connect(v._update_checkboxes)

#func _toggle(key: String):
#	var files: FE_Files = get_tree().get_first_node_in_group("fe_files")
#	files[key] = not files[key]
#	$view.get_popup()._update_checkboxes()

func _file_dialog_dir_opened(path: String):
	print("dir opened ", path)
#	file_editor.dir_open(path)

func _file_dialog_file_opened(path: String):
	print("file opened ", path)

func _file_dialog_file_saved(path: String):
	print("file saved ", path)
