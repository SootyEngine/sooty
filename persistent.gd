extends "res://addons/sooty_engine/autoloads/base_state.gd"

var a_winner := Achievement.new({
	name="The Winner",
	desc="Gain 10 prices.",
	goal=10
})

var a_massive_kill := Achievement.new({
	name="Massive Kill",
	desc="Get the massive kill.",
})
