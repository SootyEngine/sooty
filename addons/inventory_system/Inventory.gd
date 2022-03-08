extends Resource
class_name Inventory

var items: Array = []

func _init(data: Dictionary):
	UObject.patch(self, data)
