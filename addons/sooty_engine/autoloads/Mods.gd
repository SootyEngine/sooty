extends Node

const USER_DIR := "user://mods"

signal pre_installed()
signal install(dirs: Array[String])
signal installed()

signal pre_uninstalled(mod: String)
signal uninstalled(mod: String)

var auto_load_user_mods := false
var installed_dirs := []

func _init() -> void:
	install_mod("res://")
	
	if auto_load_user_mods and UFile.dir_exists(USER_DIR):
		for mod in get_user_mod_dirs():
			install_mod(mod)

func get_user_mod_dirs() -> PackedStringArray:
	return UFile.get_dirs("user://mods")

func _ready() -> void:
	_ready_deferred.call_deferred()

func _ready_deferred():
	pre_installed.emit()
	install.emit(installed_dirs)
	installed.emit()

func _print_file(path: String):
	var f = UFile.get_file_name(path)
	var h := " "
	var d := ""
	# mod from addons
	if path.begins_with("res://addons"):
		d = "[%s]" % path.substr(len("res://addons/")).get_base_dir().split("/", true, 1)[0]
	# main resource state
	elif path.begins_with("res://"):
		pass
	# external mod
	elif path.begins_with("user://mods"):
		d = "[%s]" % path.substr(len("user://mods/")).get_base_dir().split("/", true, 1)[0]
		h = "+"
	var space = " ".repeat(16 - len(f))
	print("  %s %s%s%s" % [h, f, space, d ])

func install_mod(mod: String):
	if not mod.begins_with("res://") and not mod.begins_with("user://"):
		push_error("Only mods in res:// and user:// are allowed.")
		return
	
	if not mod in installed_dirs:
		installed_dirs.append(mod)
