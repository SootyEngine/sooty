extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ready_deferred.call_deferred()

func _ready_deferred():
	var achievements := Persistent._get_all_of_type(Achievement)
	var text := ["[center;i]ACHIEVEMENTS[]"]
	for a in achievements.values():
		text.append("%s [dim]\\[%s\\][]" % [a.name, a.unlocked])
	$ColorRect/RichTextLabel.set_bbcode("\n".join(text))
