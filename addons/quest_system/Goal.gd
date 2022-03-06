extends Resource
class_name Goal

var name := ""
var desc := ""
var toll := 1
var tick := 0:
	set(t): tick = clampi(t, 0, toll)

func _init(data: Dictionary):
	UObject.patch(self, data)

func is_complete() -> bool:
	return tick == toll
