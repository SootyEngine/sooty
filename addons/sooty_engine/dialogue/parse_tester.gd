@tool
extends EditorScript

static func progress(amount: float, chars := 4) -> String:
	amount = clamp(amount, 0.0, 1.0)
	var total := amount * chars
	var filled = floor(total)
	var r = (total-filled) * 8.0
	if r:
		return "|%s%s%s|" % ["█".repeat(filled), "▏▎▍▌▋▊▉█"[r], " ".repeat(chars-filled-1)]
	else:
		return "|%s%s|" % ["█".repeat(filled), " ".repeat(chars-filled)]

func _run():
	for i in 101:
		var t = i / 100.0
		print(progress(t, 2) + " " + str(t))
