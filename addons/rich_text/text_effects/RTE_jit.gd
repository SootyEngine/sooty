# Makes words shake around.
@tool
extends RichTextEffect

# Syntax: [jit scale=1.0 freq=8.0][]
var bbcode = "jit"

const SPLITTERS := " .!?,-"

var _word := 0.0
var _last := 0
var _offset := 0

func _process_custom_fx(c: CharFXTransform):
	if c.relative_index == 0:
		_word = 0
		_offset = c.absolute_index
	
	var scale:float = c.env.get("scale", 1.0)
	var freq:float = c.env.get("jit", 1.0)
	
	if char(c.glyph_index) in SPLITTERS or char(_last) in SPLITTERS:
		_word += PI * .33
	
	var t = c.elapsed_time
	var s = fmod((_word + t + _offset) * PI * 1.25, TAU)
	var p = sin(t * freq * 16.0) * .5
	c.offset.x += sin(s) * p * scale
	c.offset.y += cos(s) * p * scale
	
	_last = c.character
	return true
