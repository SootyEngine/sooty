@tool
extends Node

signal message(type: String, payload: Variant)
signal started()
signal ended()

const VERSION := "0.1_alpha"

#const Config := preload("res://addons/sooty_engine/autoloads/Config.gd")
#const Databases := preload("res://addons/sooty_engine/autoloads/global/Databases.gd")
#const Actions := preload("res://addons/sooty_engine/autoloads/global/StringAction.gd")
#const Saver := preload("res://addons/sooty_engine/autoloads/global/SaveManager.gd")
#const Mods := preload("res://addons/sooty_engine/autoloads/global/Mods.gd")
#const Music := preload("res://addons/sooty_engine/autoloads/global/Music.gd")
#const Sound := preload("res://addons/sooty_engine/autoloads/global/Sound.gd")
#const State := preload("res://addons/sooty_engine/autoloads/State.gd")
#const Persistent := preload("res://addons/sooty_engine/autoloads/Persistent.gd")
#const Settings := preload("res://addons/sooty_engine/autoloads/Settings.gd")
#const Dialogue := preload("res://addons/sooty_engine/autoloads/Dialogue.gd")
#var config: Config = config.new()
#var databases: Databases = Databases.new()
#var actions: Actions = Actions.new()
#var saver: Saver = Saver.new()
#var mods: Mods = Mods.new()
#var music: Music = Music.new()
#var sound: Sound = Sound.new()
#var state: State = State.new()
#var persistent: Persistent = Persistent.new()
#var settings: Settings = Settings.new()
#var dialogue: Dialogue = Dialogue.new()

var config = load("res://addons/sooty_engine/autoloads/Config.gd").new()
var databases = load("res://addons/sooty_engine/autoloads/global/Databases.gd").new()
var actions = load("res://addons/sooty_engine/autoloads/global/StringAction.gd").new()
var saver = load("res://addons/sooty_engine/autoloads/global/SaveManager.gd").new()
var mods = load("res://addons/sooty_engine/autoloads/global/Mods.gd").new()
var music = load("res://addons/sooty_engine/autoloads/global/Music.gd").new()
var sound = load("res://addons/sooty_engine/autoloads/global/Sound.gd").new()
var state = load("res://addons/sooty_engine/autoloads/State.gd").new()
var persistent = load("res://addons/sooty_engine/autoloads/Persistent.gd").new()
var scenes = load("res://addons/sooty_engine/autoloads/SceneManager.gd").new()
var settings = load("res://addons/sooty_engine/autoloads/Settings.gd").new()
var dialogue = load("res://addons/sooty_engine/autoloads/Dialogue.gd").new()

var game_active := false
var flags: Array[String] = [VERSION]

func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 9223372036854775807

func _ready():
	UNode.remove_children(self)
	
	for o in [databases, mods, saver, music, sound, state, persistent, actions, scenes, settings, dialogue]:
		if o is Node:
			add_child(o)
		elif o.has_method("_ready"):
			o._ready()
	
	actions.connect_methods(self, [version, msg])

func start():
	game_active = true
	started.emit()

func end():
	game_active = false
	ended.emit()

func notify(msg: Dictionary):
	message.emit("notification", msg)

func version() -> String:
	return VERSION

func msg(type: String, payload: Variant = null):
	message.emit(type, payload)

# called by UReflect, as a way of including more advanced arg info
# for use with autocomplete
func _get_method_info(method: String):
	if method == "version":
		return { desc="Sooty Version", icon=TYPE_STRING }
