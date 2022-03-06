@tool
extends Resource
class_name Item

var name := ""
var desc := ""

func _init(data: Dictionary):
	UObject.patch(self, data)
