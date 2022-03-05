# bounces text in
tool
extends RichTextEffect

# Syntax: [back scale=8.0][/back]
var bbcode = "back"

const c1 := 1.70158
const c3 := c1 + .5

func ease_back(x):
	return c3 * x * x * x - c1 * x * x

func _process_custom_fx(c:CharFXTransform):
	var t:RichTextLabelAnimated = Global._d.get(self)
	var a := 1.0 - t._get_character_alpha(c.absolute_index)
	var scale = c.env.get("scale", 1.0)
	c.offset.y += ease_back(a) * t.size * scale
	c.color.a *= (1.0 - a)
	return true
