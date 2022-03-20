extends Node

const VERSION := "1.0"

var scenes := {}

func _init() -> void:
	add_to_group("sa:scene")
	add_to_group("sa:simple_vn_version")
	Mods.install.connect(_install_mods)
	Mods.install_mod("res://addons/simple_vn")

func simple_vn_version():
	return VERSION

func scene(id: String):
	if id in scenes:
		State.current_scene = id
		DialogueStack.halt()
		Fader.create(
			Global.get_tree().change_scene.bind(scenes[id]),
			DialogueStack.unhalt,
			{wait=1.0})
	else:
		push_error("Couldn't find scene %s." % id)

func _install_mods(dirs: Array):
	print("[Scenes]")
	for dir in dirs:
		for scene_path in UFile.get_files(dir.plus_file("scenes"), [".scn", ".tscn"]):
			Mods._print_file(scene_path)
			scenes[UFile.get_file_name(scene_path)] = scene_path
