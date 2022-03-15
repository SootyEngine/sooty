extends BaseDataClass
class_name Achievement

const MSG_ACHIEVEMENT_UNLOCKED := "achievement_unlocked"

var name := ""
var desc := ""
var toll := 1
var hide := true
var icon := "res://icon.png"

var unlocked: bool = false:
	get: return tick == toll
	set(x): tick = toll if x else 0

var progress: float = 0.0:
	get: return 0.0 if tick==0 or toll==0 else float(tick) / float(toll)

var tick := 0:
	set(x):
		var next := clampi(x, 0, toll)
		if tick != next:
			tick = next
			if unlocked:
				Global.message.emit(MSG_ACHIEVEMENT_UNLOCKED, self)

func gain(amount := 1):
	tick += amount
