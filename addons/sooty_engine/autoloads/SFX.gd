extends Node

const BUS := "sfx"
const MAX_SOUNDS := 8

var _files := {} # all playable audio
var _queue := [] # sounds waiting to be played

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("@:SFX")

func _ready():
	Mods.load_all.connect(_load_mods)
	Saver._get_state.connect(_save_state)
	Saver._set_state.connect(_load_state)

func sfx(id: String):
	play(id)

func _load_mods(mods: Array):
	_files.clear()
	for mod in mods:
		mod.meta["sfx"] = []
		for file_path in UFile.get_files(mod.dir.plus_file("audio/sfx"), UFile.EXT_AUDIO):
			_files[UFile.get_file_name(file_path)] = file_path
			mod.meta.sfx.append(file_path)

func _save_state(state: Dictionary):
	state["SFX"] = { queue=_queue }

func _load_state(state: Dictionary):
	_queue = state.get("SFX", {}).get("queue", [])

func _process(delta: float) -> void:
	if len(_queue) and get_child_count() < MAX_SOUNDS:
		_play(_queue.pop_back())
	
	for child in get_children():
		if child.get_playback_position() >= child.stream.get_length():
			_on_audio_finished(child)

func play(id: String, kwargs := {}):
	if get_child_count() >= MAX_SOUNDS:
		_queue.append(id)
	else:
		_play(id)

func has(id: String) -> bool:
	return id in _files

func _play(id: String, kwargs := {}):
	if not has(id):
		return
	
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = load(_files[id])
	player.finished.connect(_on_audio_finished.bind(player))
	player.bus = BUS
	if "scale_rand" in kwargs:
		player.pitch_scale = randf_range(1.0 - kwargs.scale_rand, 1.0 + kwargs.scale_rand)
	player.play()

func _set_volume(volume: float, player: AudioStreamPlayer):
	player.volume_db = linear2db(volume)

func _on_audio_finished(a: AudioStreamPlayer):
	remove_child(a)
	a.queue_free()
