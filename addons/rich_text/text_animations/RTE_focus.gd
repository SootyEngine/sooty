tool
extends RichTextEffect

# Syntax: [focus color][/focus]
var bbcode = "focus"

const EMBER = ord(".")

func rand(c):
	return c.character * 33.33 + c.absolute_index * 4545.5454

func _process_custom_fx(c:CharFXTransform):
	var t:RichTextLabelAnimated = Global._d.get(self)
	var a := 1.0 - t._get_character_alpha(c.absolute_index)
	var scale = c.env.get("scale", 1.0)
	
	c.color.s = lerp(c.color.s, 0.0, a)
	c.color.a = lerp(c.color.a, 0.0, a)
	var r = rand(c) * TAU
	c.offset += Vector2(cos(r), sin(r)) * t.size * scale * (a * a)
	return true
