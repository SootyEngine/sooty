@tool
extends RichTextEffect

# Syntax: [woo scale=1.0 freq=8.0][]
var bbcode = "woo"

func rand_time(c, scale:=1):
	return fmod(c.character * 12.9898 + c.absolute_index * 78.233 + c.elapsed_time * scale, 1.0)
	
func _process_custom_fx(c:CharFXTransform):
	var scale:float = c.env.get("scale", 1.0)
	var freq:float = c.env.get("freq", 8.0)
	
	if rand_time(c) > 0.5:
		if c.character >= 65 and c.character <= 90:
			c.character += 32
		elif c.character >= 97 and c.character <= 122:
			c.character -= 32 
	return true
