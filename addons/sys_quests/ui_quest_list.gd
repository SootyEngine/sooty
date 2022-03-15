extends Node

func _ready() -> void:
	_ready_deferred.call_deferred()
	Global.message.connect(_global_message)

func _global_message(msg: String, payload: Variant):
	match msg:
		Quest.MSG_STATE_CHANGED:
			_ready_deferred()

func _ready_deferred():
	var all_quests := Quest.get_all_quests().values()
	var s_started := all_quests.filter(func(x): return x.main and x.is_started)
	var s_completed := all_quests.filter(func(x): return x.main and x.is_completed)
	var s_unlocked := all_quests.filter(func(x): return x.main and x.is_unlocked)
	var s_other := all_quests.filter(func(x): return not x.main or (not x.is_started and not x.is_completed and not x.is_unlocked))
	
	var text := ["[center;i]QUESTS[]"]
	for part in [
		{text="[deep_sky_blue;b;center]Started[]", list=s_started},
		{text="[yellow_green;b;center]Completed[]", list=s_completed},
		{text="[dark_gray;b;center]Unlocked[]", list=s_unlocked},
		{text="[tomato;b;center]Debug[]", list=s_other}
	]:
		text.append(part.text)
		for quest in part.list:
			var tick = quest.get_total_complete_required()
			var toll = quest.get_total_required()
			if toll > 0:
				text.append("\t%s \\[%s/%s\\] [dim]%s[]" % [quest.name, tick, toll, quest.state])
				for subquest in quest.get_required():
					text.append("\t\t- %s [dim]%s[]" % [subquest.name, subquest.state])
			else:
				text.append("\t%s [dim]%s[]" % [quest.name, quest.state])
	
	$ColorRect/RichTextLabel.set_bbcode("\n".join(text))
