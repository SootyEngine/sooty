extends BaseDataClass
class_name VStat

const MSG_STAT_INCREASED := "state_increased"
const MSG_STAT_MAXXED := "stat_maxxed"

@export var name := ""
@export var max := 1
@export var color := Color.WHITE
@export var on_changed := ""
@export var on_increase := ""
@export var on_maxxed := ""
@export var value := 0:
	set(x):
		x = clampi(x, 0, max)
		if value != x:
			var old_v = value
			var old_m = int(value / float(notify_every))
			value = x
			var new_m = int(value / float(notify_every))
			if new_m > old_m:
				Notify.message({
					type=MSG_STAT_INCREASED,
					text=[
						"[yellow_green]+%s %s[]" % [value-old_v, name],
						"[dim]%s[] %s" % [name, value]
					],
					prog=progress
				})
			if len(on_increase):
				StringAction.do(on_increase)
			if len(on_changed):
				StringAction.do(on_changed)

@export var notify_every := 1 # notify on every change?
@export var progress := 0.0:
	get: return 0.0 if max == 0.0 else float(value) / float(max)

func _operator_get():
	return value

func _operator_set(x):
	if x is int:
		value = x

func to_string() -> String:
	return "[b;%s]%s[]" % [color, value]
