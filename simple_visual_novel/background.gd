extends TextureRect

func _init() -> void:
	add_to_group("sa:bg")

func bg(a, args: Array = [], kwargs: Dictionary = {"ok": true}):
	
	State.bg = a
	
	var path := UFile.get_user_dir().plus_file("bgs").plus_file(a)
	for e in UFile.EXT_IMAGE:
		var p = path + "." + e
		if UFile.file_exists(p):
			print("found ", p)
			set_texture(UFile.load_image(p))
			return
