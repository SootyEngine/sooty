# Simulates a "Wave Function Collapse" for each character.
@tool
extends RichTextEffect

# Syntax: [wfc][]
var bbcode = "wfc"

const SPACE := " "
const SYMBOLS := "10"

func rand2(c: CharFXTransform):
	return abs(sin(c.absolute_index * 321.123 + c.elapsed_time * 0.025))
	
func rand(c: CharFXTransform):
	return int(sin(c.absolute_index * 321.123 + c.elapsed_time * 0.025) * 100.0)

func _process_custom_fx(c: CharFXTransform):
	var t: RichTextAnimation = instance_from_id(get_meta("rt"))
	var a := t._get_character_alpha(c.absolute_index)
	
	if t.fade_out:
		var aa = a + rand2(c) * a
		if aa < 1.0 and c.character != SPACE:
			c.character = SYMBOLS[rand(c) % len(SYMBOLS)]
			c.color.v -= .5
		
	else:
		var aa = a + rand2(c) * a
		if aa < 1.0 and c.character != SPACE:
			c.character = SYMBOLS[rand(c) % len(SYMBOLS)]
			c.color.v -= .5
	
	c.color.a = a
	return true
