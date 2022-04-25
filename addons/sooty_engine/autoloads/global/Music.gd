@tool
extends Node

const BUS := "music"
const DEFAULT_FADE_TIME := 2.0
const MAX_MUSIC_PLAYERS := 3

@export var _queue := []
@export var _files := {}

func _ready():
	Sooty.actions.connect_as_node(self, "Music")
	Sooty.actions.connect_methods(self, [play_music])
	
	Sooty.mods.load_all.connect(_load_mods)
	Sooty.saver._get_state.connect(_save_state)
	Sooty.saver._set_state.connect(_load_state)

func _get_method_info(method: String):
	match method:
		"play_music":
			return {
				args={
					id={
						# auto complete list of music files
						options=func(): return _files.keys(),
						icon=preload("res://addons/sooty_engine/icons/music.png"),
					}
				}
			}

func _load_mods(mods: Array):
	for mod in mods:
		mod.meta["music"] = []
		var dir = mod.dir.plus_file("audio/music")
		var got = UFile.get_files(dir, UFile.EXT_AUDIO)
		for file_path in got:
			var id := UFile.get_file_name(file_path)
			_files[id] = file_path
			mod.meta.music.append(file_path)

func _save_state(state: Dictionary):
	var player := get_current_player()
	if player:
		var id: String = player.get_meta("id")
		var pos := player.get_playback_position()
		state["Music"] = { id=id, pos=pos }
	else:
		state["Music"] = {}

func _load_state(state: Dictionary):
	var m = state.get("Music", {})
	if "id" in m:
		play_music(m, { pos=m.get("pos", 0.0) })

func has(id: String) -> bool:
	return id in _files

func get_current() -> String:
	var c := get_current_player()
	return "" if not c else c.get_meta("id")

func _get_children():
	return UGroup.get_all("_music_")

func get_current_player() -> AudioStreamPlayer:
	for player in _get_children():
		if player.get_meta("state") == "playing":
			return player
	return null

func stop():
	for child in _get_children():
		child.queue_free()

func fade_out(fade_time := DEFAULT_FADE_TIME):
	for player in _get_children():
		player.set_meta("state", "fading_out")
		
		var tween := Global.get_tree().create_tween()
		tween.bind_node(player)
		tween.tween_method(_set_volume.bind(player), 1.0, 0.0, fade_time)\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_IN)
		tween.tween_callback(player.queue_free)

func queue(id: String):
	if id in _files:
		if len(_queue):
			_queue.append(id)
		else:
			play_music(id)

# kwarg (default value):
# - pos (0.0): Position to play from.
# - rand_offset: Random position to play from on start up.
# - fade_time (DEFAULT_FADE_TIME): Time to fade out over.
func play_music(id: String, kwargs := {}):
	if Engine.is_editor_hint():
		return
	
	if id == get_current():
		push_warning("Already playing '%s'." % id)
		return
	
	if len(_get_children()) >= MAX_MUSIC_PLAYERS:
		push_error("Too many music players.")
		return
	
	if not has(id):
		push_error("No music '%s'." % id)
		return
	
	var fade_time = kwargs.get("time", DEFAULT_FADE_TIME)
	fade_out(fade_time)
	
	var player := AudioStreamPlayer.new()
	Global.add_child(player)
	player.add_to_group("_music_")
	player.set_meta("id", id)
	player.set_meta("state", "playing")
	player.stream = load(_files[id])
	player.finished.connect(_on_music_finished.bind(player))
	player.bus = BUS
	
	var play_pos: float = kwargs.get("pos", 0.0)
	if "rand_offset" in kwargs:
		play_pos = kwargs.rand_offset * player.stream.get_length()
	player.play(play_pos)
	
	var tween := Global.get_tree().create_tween()
	tween.bind_node(player)
	tween.tween_method(_set_volume.bind(player), 0.0, 1.0, fade_time)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)

func _set_volume(volume: float, player: AudioStreamPlayer):
	player.volume_db = linear2db(volume)

func _on_music_finished(a: AudioStreamPlayer):
	a.queue_free()
