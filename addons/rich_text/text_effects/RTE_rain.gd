@tool
extends RichTextEffect

# Syntax: [rain][]
var bbcode = "rain"

func rand(c:CharFXTransform) -> float:
	return fmod(c.character * 12.9898 + c.absolute_index * 78.233, 1.0)

func _process_custom_fx(c:CharFXTransform):
	var time = c.elapsed_time
	var r = rand(c)
	var t = fmod(r + time * .5, 1.0)
	c.offset.y += t * 8.0
	c.color.a = lerp(c.color.a, 0.0, t)
	return true
