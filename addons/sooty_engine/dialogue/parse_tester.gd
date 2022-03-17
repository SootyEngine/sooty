@tool
extends EditorScript

var x = "Who"
var y = [9,1,1]

func Character(x):
	print("CALLED Character WITH ", x)

enum {WINTER, SPRING}

func _run():
	print(self["WINTER"], self["SPRING"])
	return
#
##	var cmd := """p = @Character({"Paul", 10, false, [{x}, {y}, "otherwise"]})"""
#	var shortcut := """@char x:123 y:who_cares"""
#	var p := shortcut.split(" ", true, 1)
#	var fname = p[0].substr(1)
#	shortcut = p[1]
#	var cmd: String = Config.new("res://config.cfg").get_value("sooty_shortcuts", fname)
#	var prop = StringAction.get_properties(shortcut)
#	prop = UDict.map_values(prop[-1], func(x): return var2str(x))
#	var out := cmd.format(prop)
#
#	out = UString.replace_between(out, "@", "(", func(i,s): return "_calls.%s.call" % s)
#	out = UString.replace_between(out, "_(", ")", func(i,s): return "tr(%s)" % s)
#
#	print(out)


#	print(StringAction.do("$state.score += 20"))
#	var d := DialogueParser.parse("res://dialogue/flattest.soot")
#	for step in d.lines:
#		scan(step, d.lines[step])

#	print(UString.is_at("Once upon a time", "upon", 4))
#	print(UString.extract("<All around (((the world ((internal)) ))) there is a thing.>", "(((", ")))"))
