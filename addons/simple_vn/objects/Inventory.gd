extends BaseDataClass
class_name Inventory

signal gained(type: Item, quantity: int)
signal lost(type: Item, quantity: int)
signal equipped(type: Item, slot: String)
signal unequipped(type: Item, slot: String)

var items := []
var worn := {}
var slots := ""

func _get(property: StringName):
	if has(str(property)):
		return count(str(property))

func has(type: String, quantity := 1) -> bool:
	var q := 0
	for i in len(items):
		if items[i].type == type:
			q += items[i].total
		if q >= quantity:
			return true
	return false

func get_slot_info() -> EquipmentSlots:
	if State._has(slots):
		return State._get(slots)
	return EquipmentSlots.new()

func count(type: String) -> int:
	var out := 0
	for i in len(items):
		if items[i].type == type:
			out += items[i].total
	return out

func gain(type: String, quantity := 1, _meta := {}):
	if not Item.exists(type):
		push_error("No item type '%s'." % type)
		return
	
	var info := Item.get_item(type)
	var q := quantity
	
	# try to append to previous slots
	for item in items:
		if item.type == type and item.total < info.slot_max:
			var amount := mini(info.slot_max, q)
			item.total += amount
			q -= amount
			if q <= 0:
				break
	
	# create new slots for leftovers
	for i in ceil(q / float(info.slot_max)):
		var amount := mini(info.slot_max, q)
		q -= amount
		items.append({ type=type, total=amount })
	
	var dif := quantity - q
	gained.emit(info, dif)

func lose(type: String, quantity := 1, _meta := {}):
	if not Item.exists(type):
		push_error("No item type '%s'." % type)
		return
	
	var info := Item.get_item(type)
	var q := quantity
	
	for i in range(len(items)-1, -1, -1):
		var item = items[i]
		if item.type == type:
			var amount := mini(item.total, q)
			item.total -= amount
			q -= amount
			if q <= 0:
				items.remove_at(i)
				break
	
	var dif := quantity - q
	lost.emit(info, dif)

func wear(type: String, slot: String = "", gain_if_has_not := false):
	var info := Item.get_item(type)
	# does slot exist?
	if not get_slot_info().has_slot(slot):
		push_error("No slot '%s' in '%s'." % [slot])
		return
	
	# not wearable
	if not info.is_wearable():
		push_error("Item '%s' isn't wearable.")
		return
	
	# don't have it
	if not has(type) and not gain_if_has_not:
		push_error("Can't wear item you don't have. Call wear(id, slot, true).")
		return
	
	# take off items in other slots
	if slot in worn:
		bare_at(slot)
	
	# bare any other slots
	for b in get_slot_info().slots[slot].bare:
		bare_at(b)
	
	worn[slot] = { type=type }

func bare(type: String):
	for slot in worn:
		if worn[slot].type == type:
			worn.erase(slot)
			break

func bare_at(slot: String):
	if slot in worn:
		pass

