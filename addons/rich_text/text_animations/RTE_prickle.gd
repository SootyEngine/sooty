# Fades characters in more randomly.
# You should set 'fade_speed' to a low value for this to look right. 
@tool
extends RichTextEffect

# Syntax: [prickle pow=2][]
var bbcode = "prickle"

func rand(c):
	return fmod(c.character * 33.33 + c.absolute_index * 4545.5454, 1.0)

func _process_custom_fx(c: CharFXTransform):
	var t: RichTextAnimation = instance_from_id(get_meta("rt"))
	var power:float = c.env.get("pow", 2.0)
	var a := t._get_character_alpha(c.absolute_index)
	var r = rand(c)
	a = clamp(a * 2.0 - r, 0.0, 1.0)
	a = pow(a, power)
	c.color.a = a
	return true
