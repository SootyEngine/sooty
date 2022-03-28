extends Node

const USER_DIR := "user://mods"
const AUTO_INSTALL_USER_MODS := false

signal pre_loaded()
signal load_all(list: Array)
signal loaded()

var mods := {}

func _init():
	_add_mod("res://", true)
	
	if UFile.dir_exists(USER_DIR):
		for mod in get_user_mod_dirs():
			_add_mod(mod, AUTO_INSTALL_USER_MODS)

func _ready() -> void:
	_update.call_deferred()

func get_user_mod_dirs() -> PackedStringArray:
	return UFile.get_dirs("user://mods")

func get_installed() -> Array:
	var filtered := mods.values().filter(func(x): return x.installed)
	filtered.sort_custom(func(a, b): return a.get_priority() < b.get_priority())
	return filtered

func get_uninstalled() -> Array:
	var filtered := mods.values().filter(func(x): return not x.installed)
	filtered.sort_custom(func(a, b): return a.get_priority() < b.get_priority())
	return filtered

func install(dir: String):
	if not mods[dir].installed:
		mods[dir].installed = true
		_update()

func uninstall(dir: String):
	if mods[dir].installed:
		mods[dir].installed = false
		_update()

func _update():
	pre_loaded.emit()
	
	var installed := get_installed()
	for mod in installed:
		mod.meta.clear()
	
	load_all.emit(installed)
	
	# Display lists of what was added by the mods.
	var meta := {}
	for k in installed[0].meta.keys():
		meta[k] = []
	print("[Mods - %s]" % [len(installed)])
	for i in len(installed):
		var mod = installed[i]
		print("\t%s %s" % [i+1, mod.dir])
		for k in mod.meta:
			meta[k].append_array(mod.meta[k])
	for k in meta:
		print("[%s - %s]" % [k.capitalize(), len(meta[k])])
		for i in len(meta[k]):
			print("\t%s %s" % [i+1, meta[k][i].get_file()])
	
	loaded.emit()

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

func _add_mod(mod_dir: String, install: bool):
	if not mod_dir.begins_with("res://") and not mod_dir.begins_with("user://"):
		push_error("Only mods in res:// and user:// are allowed.")
		return
	
	if not mod_dir in mods:
		mods[mod_dir] = ModInfo.new(mod_dir, install)
