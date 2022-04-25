@tool
extends EditorScript


func _run():
	for i in 24:
		var x = "12%s lb" % i
		prints(x, Unit.mass(x, "g"))
#		var x = "6'%s\"" % i
#		print(x)
#		var feet = Unit.length(x, "in")
#		print("\t", feet)
#		print("\t", Unit.length(feet, "ft in", "in"))
