@tool
extends Node

const BUS := "sfx"
const MAX_SOUNDS := 8

var _files := {} # all playable audio
var _queue := [] # sounds waiting to be played

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("@:SFXManager")
	add_to_group("@.play_sfx")

func _ready():
	ModManager.load_all.connect(_load_mods)
	SaveManager._get_state.connect(_save_state)
	SaveManager._set_state.connect(_load_state)

# called by UReflect, as a way of including more advanced arg info
# for use with autocomplete
func _get_method_info(method: String):
	if method == "play" or method == "play_sfx":
		return {
			args={
				id={
					options=func(): return _files.keys(),
					icon=preload("res://addons/sooty_engine/icons/sfx.png"),
				}
			}
		}

func _load_mods(mods: Array):
	_files.clear()
	for mod in mods:
		mod.meta["sfx"] = []
		var head: String = mod.dir.plus_file("audio/sfx")
		for file_path in UFile.get_files(head, UFile.EXT_AUDIO):
			var id = UFile.trim_extension(file_path.trim_prefix(head + "/"))#.replace("/", "-"))
			_files[id] = file_path
			mod.meta.sfx.append(id)#file_path)

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

# used as an action shortcut
func play_sfx(id: String, fart: bool = false):# kwargs := {}):
	play(id)#, kwargs)

func play(id: String, kwargs := {}):
	if Engine.is_editor_hint():
		return
	
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
