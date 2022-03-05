tool
extends RichTextEffect

# Syntax: [console][/console]
var bbcode = "console"

const SPACE := ord(" ")
const CURSOR := ord("█")
const CURSOR_COLOR := Color.greenyellow

func _process_custom_fx(c:CharFXTransform):
	var t:RichTextLabelAnimated = Global._d.get(self)
	
	if t.fade_out:
		var a := t._get_character_alpha(c.absolute_index)
		c.color.a *= a
		c.offset.y -= t.size * .5 * (1.0 - a)
		
	else:
		if t.percent == 1.0:
			if t.visible_character-1 == c.absolute_index and sin(c.elapsed_time * 16.0) > 0.0:
				c.character = CURSOR
				c.color = CURSOR_COLOR
				c.offset = Vector2.ZERO
		
		else:
			
			if t.visible_character == c.absolute_index:
				if c.character == SPACE:
					c.color.a = 0.0
				else:
					c.character = CURSOR
					c.color = CURSOR_COLOR
					c.offset = Vector2.ZERO
			
			else:
				c.color.a *= t._get_character_alpha(c.absolute_index)
	
	return true
