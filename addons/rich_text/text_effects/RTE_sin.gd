@tool
extends RichTextEffect

# Syntax: [sin][]
var bbcode = "sin"

func _get_method_info(method: String):
	return {
		desc="Animate characters a waveform",
		auto="sin=1.0 freq=1.0 speed=1.0",
		kwargs={
			sin={desc="Height of curve"},
			freq={desc="Width of bobbing across characters"},
			speed={desc="Speed of bobbinb"}
		}
	}

func _process_custom_fx(c: CharFXTransform):
	var t: RichTextLabel2 = instance_from_id(get_meta("rt"))
	var sn: float = c.env.get("sin", 1.0)
	var fr: float = c.env.get("freq", 1.0)
	var sp: float = c.env.get("speed", 1.0)
	c.offset.y += sin(c.elapsed_time * 12.0 * sp + c.range.x * fr) * t.font_size * .05 * sn
	return true
