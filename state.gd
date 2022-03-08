extends Node

func _init():
	add_to_group("sa:quest")
	add_to_group("sa:gain")
	add_to_group("sa:lose")

func quest(id: String, action: String, args: Array):
	print("Called quest(%s)!" % [id, action, args])

func gain(item: String, amount: int = 1, kwargs: Dictionary = {}):
	player.inventory.gain(item, amount, kwargs)

func lose(item: String, amount: int = 1, kwargs: Dictionary = {}):
	player.inventory.lose(item, amount, kwargs)

var score := 1
var choice := ""
var day_of_week := "monday"

var player := Character.new({
	name="Player",
	color=Color.TOMATO,
	inventory={
		slots=equipment_slots,
		items=[
			{type="coin", total=12356}
		]
	}
})

var paul := Character.new({
	name="Paul",
	color=Color.PLUM,
	inventory={
		slots=equipment_slots,
		items=[
			{type="coin", total=10}
		]
	},
	health=12309
})

var mary := Character.new({
	name="Mary"
})

# QUESTS

var q_the_winner := Quest.new({
	name="The Winner",
	desc="Get the winner before anyone else does.",
	goals={
		knife=Goal.new({
			name="Knife",
			toll=10
		})
	}
})

# ITEMS

var coin := Item.new({name="Coin"})

var apple := Item.new({name="Apple"})
var pear := Item.new({name="Pear"})
var plump := Item.new({name="Plump"})

# ITEM SLOTS
var equipment_slots := EquipmentSlots.new({
	slots={
		head={},
		torso={bare=["two_piece"]},
		legs={bare=["two_piece"]},
		two_piece={bare=["torso", "legs"]}
	}
})
