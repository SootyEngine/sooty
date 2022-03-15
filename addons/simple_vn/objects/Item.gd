extends BaseDataClassExtra
class_name Item

var name := ""
var desc := ""
var slot_max := 1:
	get: return 1 if is_wearable() else slot_max
var worn_to := []

func is_wearable() -> bool:
	return len(worn_to) > 0

static func get_item(type: String) -> Item:
	return null if not exists(type) else State[type]

static func exists(id: String) -> bool:
	return State._has_of_type(id, Item)

static func get_all_items() -> Dictionary:
	return State._get_all_of_type(Item)
