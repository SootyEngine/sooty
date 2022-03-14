@tool
extends EditorScript

func _run():
#	print(UString.find_either("one it >> happens @happens :: who cares >> what about.", [">>", "@", "::"]))
#	UDict.log(get_trailing_tokens("one it >> happens @happens :: who cares >> what about.", [">>", "@", "::"]))

#	var already := {}
#	var collisions := 0
#	var total := 0
#	for i in 500:
#		var uid = get_uuid()
#		total += 1
#		while uid in already:
#			uid = get_uuid()
#			total += 1
#			collisions += 1
#		already[uid] = true
#	print("collisions: %s / %s" % [collisions, total])
#	return
	
	var d := DialogueParser.parse("res://dialogue/flattest.soot")
	for step in d.lines:
		scan(step, d.lines[step])

func scan(id: String, step: Dictionary):
	id = id.split("!", true, 1)[-1]
	if "type" in step:
		match step.type:
			"text": prints(id, "TXT:", step)
			"option": prints(id, "OPP:", step)
			_: print(step)
#	print(UString.is_at("Once upon a time", "upon", 4))
#	print(UString.extract("<All around (((the world ((internal)) ))) there is a thing.>", "(((", ")))"))
