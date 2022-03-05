tool
extends RichTextEffect

# Syntax: [redact freq wave][]
var bbcode = "redact"

const SPACE := ord(" ")
const BLOCK := ord("█")
const MID_BLOCK := ord("▓")

func _process_custom_fx(c:CharFXTransform):
	var t:RichTextLabelAnimated = Global._d.get(self)
	var a := t._get_character_alpha(c.absolute_index)
	
	if t.fade_out:
		c.color.a = a
	
	else:
		if a == 0 and (c.character != SPACE or c.relative_index % 2 == 0):
			var freq:float = c.env.get("freq", 1.0)
			var scale:float = c.env.get("scale", 1.0)
			c.character = MID_BLOCK if a < 1.0 else BLOCK
			c.color = Color.black
			c.offset = Vector2.ZERO
#			c.offset.y = sin(c.absolute_index * freq) * scale
	
	return true
