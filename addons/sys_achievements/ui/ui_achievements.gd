extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_deferred.call_deferred()
	Global.message.connect(_global_message)

func _global_message(msg: String, payload: Variant):
	match msg:
		Achievement.MSG_ACHIEVEMENT_PROGRESS, Achievement.MSG_ACHIEVEMENT_UNLOCKED:
			_ready_deferred()

func _ready_deferred():
	var achievements := Persistent._get_all_of_type(Achievement)
	var text := ["[center;i]ACHIEVEMENTS[]"]
	for a in achievements.values():
		var clr = Color.YELLOW_GREEN if a.unlocked else Color.TOMATO
		text.append("[%s]%s[] [dim][0.5]\\[%s\\][]" % [clr, a.name, a.unlocked])
	$ColorRect/RichTextLabel.set_bbcode("\n".join(text))
