extends BaseDataClass
class_name Quest

const MSG_STATE_CHANGED := "MSG_STATE_CHANGED"

const QUEST_NOT_STARTED := "NOT_STARTED"
const QUEST_STARTED := "STARTED"
const QUEST_COMPLETED := "COMPLETED"
const QUEST_FAILED := "FAILED"
const QUEST_UNLOCKED := "UNLOCKED"

signal state_changed(quest: Quest)

var name := ""
var desc := ""
var goal := false
var state := QUEST_NOT_STARTED:
	set(x):
		if state != x:
			state = x
			
			# broadcast state change, if main.
			if not goal:
				var msg := { text="[tomato]%s[]" % name }
				match state:
					QUEST_COMPLETED:
						msg.type = "Quest Complete"
						Notify.message(msg)
					QUEST_STARTED:
						msg.type = "Quest Started"
						Notify.message(msg)
				Global.message.emit(MSG_STATE_CHANGED, self)
			
			# alert.
			state_changed.emit(self)

var requires: Array[String] = [] # quests that need to be complete for this one to work.
var unlocks: Array[String] = [] # quests that will be unlcoekd when this one is complete.
var rewards: Array[String] = [] # rewards that will be unlocked.

func _post_init():
	super._post_init()
	for quest in get_required():
		quest.state_changed.connect(_subquest_state_changed)

func _subquest_state_changed(subquest: Quest):
	prints(self, goal, "SUBQUEST CHANGED", subquest)
	
	if not goal:
		var msg := {
			text="[tomato]%s[]\n%s" % [name, subquest.name],
			type="Goal Complete\n[hide].[]",
			prog=get_progress()
		}
		Notify.message(msg)
		Global.message.emit(MSG_STATE_CHANGED, self)
		if get_total_complete_required() >= get_total_required():
			complete()

func get_required() -> Array[Quest]:
	var all := State._get_all_of_type(Quest)
	var out := []
	for k in requires:
		if k in all:
			out.append(all[k])
		else:
			push_error("No quest %s. %s" % [k, all])
	return out

var is_completed: bool:
	get: return state == QUEST_COMPLETED

var is_started: bool:
	get: return state == QUEST_STARTED

var is_unlocked: bool:
	get: return state == QUEST_UNLOCKED

func get_total_required() -> int:
	return len(requires)

func get_total_complete_required() -> int:
	var out := 0
	for quest in get_required():
		if quest.is_completed:
			out += 1
	return out

func get_progress() -> float:
	var toll := get_total_required()
	var tick := get_total_complete_required()
	if tick == 0 or toll == 0:
		return 0.0
	return float(tick) / float(toll)

func has_requirements() -> bool:
	for quest in get_required():
		if not quest.is_completed:
			return false
	return true

func start(force := false):
	if force or has_requirements():
		state = QUEST_STARTED
	else:
		push_error("%s doesn't meet it's requirements." % self)

func complete():
	if state != QUEST_COMPLETED:
		state = QUEST_COMPLETED

static func exists(id: String) -> bool:
	return State._has_of_type(id, Quest)

static func get_all_quests() -> Dictionary:
	return State._get_all_of_type(Quest)
