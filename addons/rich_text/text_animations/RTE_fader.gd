# Fades words in one at a time.
# Syntax: [fader][]
@tool
extends RichTextEffect

var bbcode = "fader"

func _process_custom_fx(c:CharFXTransform):
	var t:RichTextAnimation = Global.T.get(self)
	if not t:
		return true
	var a := t._get_character_alpha(c.range.x)
	c.color.a *= a
	return true
