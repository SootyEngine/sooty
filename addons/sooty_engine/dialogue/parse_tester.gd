@tool
extends EditorScript

func _run():
#
#	var exp := Expression.new()
#	exp.parse("max(10, 20)")
#	print(exp.execute())
#
#	return

	Mods.load_mods(false)
	State.changed_from_to.connect(func(x, f, t): print("CHANGED %s FROM %s TO %s" % [x, f, t]))
	var f := Flow.new(Dialogue._lines, Dialogue._flows)
	prints(f.execute("East"), State.score)
	
#	pri.nt("Okay")
