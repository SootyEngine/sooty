extends Node

func _init():
	add_to_group("sa:quest")
	add_to_group("sa:gain")
	add_to_group("sa:lose")

func quest(id: String, action: String, args: Array):
	print("Called quest(%s)!" % [id, action, args])

func gain(item: String, amount: int = 1, kwargs: Dictionary = {}):
	player.inventory.gain(item, amount)

func lose(item: String, amount: int = 1, kwargs: Dictionary = {}):
	player.inventory.lose(item, amount)

var score := 1
var choice := ""

var player := Character.new({
	name="Player",
	inventory={
		items=[
			{type="coin", total=12356}
		]
	}
})

var paul := Character.new({
	name="Paul",
	inventory={
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
