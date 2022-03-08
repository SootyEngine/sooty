# Fades words in one at a time.
@tool
extends RichTextEffect

# Syntax: [fader][]
var bbcode = "fader"

func _process_custom_fx(c: CharFXTransform):
	var t: RichTextAnimation = instance_from_id(get_meta("rt"))
	if not t:
		return true
	var a := t._get_character_alpha(c.range.x)
	c.color.a *= a
	return true
