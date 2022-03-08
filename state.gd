extends Node

var score := 1
var choice := ""

var paul := Character.new({
	name="Paul",
	inventory=Inventory.new({
		items=[
			{id="coin", total=10}
		]
	}),
	health=12309
})

var mary := Character.new({
	name="Mary"
})

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
