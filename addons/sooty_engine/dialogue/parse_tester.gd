@tool
extends EditorScript

func _run():
	var e := Expression.new()
	e.parse("{'x':true}")
	print(e.execute())
#	print(Flow._evaluate_path("_start", "._end"))
#	var command := "score += sin(20) + @ok * @okay(2, false)"
##	var parts := UString.split_outside(command, " ")
##	for part in parts:
##		print(part)
#	print(Sooty.actions.preprocess_eval(command))
#	var got = Soot2.parse(["res://dialogue/empty_scene.soot"])
#	UDict.log(got)
