@tool
extends RichTextEffect

# Syntax: [jump2 angle=45][]
var bbcode = "jump2"

func _process_custom_fx(c: CharFXTransform):
	var t:RichTextAnimation = instance_from_id(get_meta("rt"))
	var a := deg2rad(c.env.get("angle", 0))
	var s := sin(-c.elapsed_time * 4.0 + c.relative_index * PI * .125)
	s = -abs(pow(s, 4.0)) * 2.0
	s *= c.env.get("size", 1.0) * t.size * .125
	c.offset.x += sin(a) * s
	c.offset.y += cos(a) * s
	return true
