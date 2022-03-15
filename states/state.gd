extends Node

var score := 0
var choice := ""
var day_of_week := "monday"
var time := DateTime.new({weekday="sat"})

var school_boy := Character.new({
	name="School Boy",
	color=Color.AQUAMARINE
})

var player := Character.new({
	name="Player",
	color=Color.TOMATO,
	inventory={
		slots="equipment_slots",
		items=[
			{type="coin", total=12356}
		]
	}
})

var paul := Character.new({
	name="Paul",
	color=Color.PLUM,
	inventory={
		slots="equipment_slots",
		items=[
			{type="coin", total=10}
		]
	},
	health=12309
})

var mary := Character.new({name="Mary"})

var LVL := Level.new({name="Level", max=20})
var STR := Level.new({name="STR", max=100, notify_modulo=10})
var WIS := Level.new({name="STR", max=100, notify_modulo=10})
var CHR := Level.new({name="CHR", max=100, notify_modulo=10})

# QUESTS

var q_the_winner := Quest.new({
	name="The Winner",
	desc="Get the winner before anyone else does.",
	requires=["q_FindTheKnife", "q_FindTheSpoon"]
})
var q_FindTheKnife := Quest.new({goal=true, name="Find the knife"})
var q_FindTheSpoon := Quest.new({goal=true, name="Find the spoon"})

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
