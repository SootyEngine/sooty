@tool
extends Node

@export var tats = true

func _get_tool_buttons():
	return ["test"]

func _init():
	add_to_group("sa:bg")

func test():
	StringAction.do("bg 1 2 3 dmg:20 pwr:3,4")

const _bg_ARGS := ["", "args", "kwargs"]
func bg(a, args: Array = [], kwargs: Dictionary = {}):
	var path := UFile.get_user_dir().plus_file("bgs").plus_file(a)
	
	State.bg = a
	
	for e in UFile.EXT_IMAGE:
		var p = path + "." + e
		print("check for ", p)
		if UFile.file_exists(p):
			$bg.set_texture(UFile.load_image(p))
			return
	print("couldnt find it")
	
	prints("GOT", a, args, kwargs)
