@tool
extends EditorScript

func _run():
	print(StringAction.do("$state.score += 20"))
#	var d := DialogueParser.parse("res://dialogue/flattest.soot")
#	for step in d.lines:
#		scan(step, d.lines[step])

#	print(UString.is_at("Once upon a time", "upon", 4))
#	print(UString.extract("<All around (((the world ((internal)) ))) there is a thing.>", "(((", ")))"))
