# Offsets characters by an amount.
tool
extends RichTextEffect

# Syntax: [off][]
var bbcode = "off"

func to_float(s:String):
	if s.begins_with("."):
		return float("0" + s)
	return float(s)

func _process_custom_fx(c:CharFXTransform):
	var off = c.env.get("off", Vector2.ZERO)
	match typeof(off):
		TYPE_REAL, TYPE_INT: c.offset.y += off
		TYPE_VECTOR2: c.offset += off
		TYPE_ARRAY: c.offset += Vector2(off[0], off[1])
		_: print(off)
	return true
