extends Resource
class_name Quest

enum State { NOT_STARTED, STARTED, COMPLETED, FAILED }

var name := ""
var desc := ""
var state := State.NOT_STARTED
var goals := {}

func _init(data: Dictionary):
	UObject.patch(self, data)

func is_complete() -> bool:
	for g in goals.values():
		if not g.is_complete():
			return false
	return true
