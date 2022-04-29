@tool
extends "res://addons/sooty_engine/autoloads/ResManager.gd"

const BUS := "sfx"
const MAX_SOUNDS := 8

var _queue := [] # sounds waiting to be played

func _ready():
	Sooty.actions.connect_as_node(self)
	Sooty.actions.connect_methods([play_sound])
	Sooty.mods.load_all.connect(_load_mods)
	Sooty.saver._get_state.connect(_save_state)
	Sooty.saver._set_state.connect(_load_state)

# called by UReflect, as a way of including more advanced arg info
# for use with autocomplete
func _get_method_info(method: String):
	if method == "play_sound":
		return {
			args={
				id={
					options=get_all_ids,
					icon=preload("res://addons/sooty_engine/icons/sfx.png"),
				}
			}
		}

func _get_res_dir():
	return "audio/sound"

func _get_res_extensions():
	return UFile.EXT_AUDIO

func _save_state(state: Dictionary):
	state["Sound"] = { queue=_queue }

func _load_state(state: Dictionary):
	_queue = state.get("Sound", {}).get("queue", [])

func _get_audio() -> Array:
	return UGroup.get_all("_sound_")
	
func _process(delta: float) -> void:
	if len(_queue) and len(_get_audio()) < MAX_SOUNDS:
		_play(_queue.pop_back())
	
	for child in _get_audio():
		if child.get_playback_position() >= child.stream.get_length():
			_on_audio_finished(child)

# used as an action shortcut
func play_sound(id: String, kwargs := {}):
	if Engine.is_editor_hint():
		return
	
	if len(_get_audio()) >= MAX_SOUNDS:
		_queue.append(id)
	else:
		_play(id)

func _play(id: String, kwargs := {}):
	var path := find(id)
	if path:
		var player := AudioStreamPlayer.new()
		player.add_to_group("_sound_")
		Global.add_child(player)
		player.stream = load(find(id))
		player.finished.connect(_on_audio_finished.bind(player))
		player.bus = BUS
		if "scale_rand" in kwargs:
			player.pitch_scale = randf_range(1.0 - kwargs.scale_rand, 1.0 + kwargs.scale_rand)
		player.play()

func _set_volume(volume: float, player: AudioStreamPlayer):
	player.volume_db = linear2db(volume)

func _on_audio_finished(a: AudioStreamPlayer):
	a.queue_free()
