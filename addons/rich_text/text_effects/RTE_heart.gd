@tool
extends RichTextEffect


# Syntax: [heart scale=1.0 freq=8.0][]
var bbcode = "heart"

const HEART := "♡"
const TO_CHANGE := "oOaA"

func _process_custom_fx(c: CharFXTransform):
	var scale:float = c.env.get("scale", 16.0)
	var freq:float = c.env.get("freq", 2.0)

	var x =  c.absolute_index / scale - c.elapsed_time * freq
	var t = abs(cos(x)) * max(0.0, smoothstep(0.712, 0.99, sin(x))) * 2.5;
	c.color = c.color.lerp(Color.BLUE.lerp(Color.RED, t), t)
	c.offset.y -= t * 4.0
	
	if c.offset.y < -1.0:
		if c.character in TO_CHANGE:
			c.character = HEART
	
	return true
