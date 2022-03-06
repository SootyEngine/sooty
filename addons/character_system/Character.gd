extends Resource
class_name Character

var name := ""
var format := "[b;{color}]{name}[]"
var color := Color.WHITE
var inventory := Inventory.new({})

func _init(data: Dictionary):
	UObject.patch(self, data)
