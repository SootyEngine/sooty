extends BaseDataClass
class_name BaseDataClassExtra

var data := {}

func _init(d := {}):
	UObject.patch(self, d, true)
	for k in d:
		data[k] = d[k]
	_post_init.call_deferred()

func _get(property: StringName):
	if str(property) in data:
		return data[str(property)]

func _set(property: StringName, value) -> bool:
	if str(property) in data:
		data[str(property)] = value
		return true
	return false
