@tool
extends RefCounted

const PATH := "res://config.soda"
var data := {}
var modified_at := 0

func _init():
	_reload()

func _ready():
	_timer.call_deferred()

func _reload():
	data = DataParser.new().parse(PATH, true).data
	modified_at = UFile.get_modified_time(PATH)
	print("Loaded Config: %s." % PATH)
#	UDict.log(data)

func _timer():
	if UFile.get_modified_time(PATH) != modified_at:
		_reload()
	Global.get_tree().create_timer(1.0).timeout.connect(_timer)

func _get(property: StringName) -> Variant:
	return UDict.get_at(data, str(property).split("."), false)

func getor(property: String, default: Variant) -> Variant:
	var got = _get(property)
	return got if got != null else default
