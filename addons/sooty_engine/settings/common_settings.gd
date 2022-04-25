extends Node

var full_screen := false:
	set(v):
		full_screen = v
		if full_screen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

var resolution := Vector2i(1080, 720):
	set(v):
		var min_size := Vector2i(640, 480)# DisplayServer.window_get_min_size()
		var max_size := Vector2i(1920, 1080)# DisplayServer.window_get_max_size()
		v.x = clampi(v.x, min_size.x, max_size.x)
		v.y = clampi(v.y, min_size.y, max_size.y)
		DisplayServer.window_set_size(v)

var music_volume := 1.0:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(Sooty.music.BUS), linear2db(music_volume))

var music_mute := false:
	set(v):
		music_mute = v
		AudioServer.set_bus_mute(AudioServer.get_bus_index(Sooty.music.BUS), music_mute)

var sfx_volume := 1.0:
	set(v):
		sfx_volume = clampf(v, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(Sooty.sound.BUS), linear2db(sfx_volume))

var sfx_mute := false:
	set(v):
		sfx_mute = v
		AudioServer.set_bus_mute(AudioServer.get_bus_index(Sooty.sound.BUS), sfx_mute)
