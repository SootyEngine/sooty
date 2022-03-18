@tool
extends EditorScript

var x = "Who"
var y = [9,1,1]

func Character(x):
	print("CALLED Character WITH ", x)

enum {WINTER, SPRING}

func _run():
	var test := "someFunc(a,b,func1(a,b+c),func2(a*b,func3(a+b,c)),func4(e)+func5(f),func6(func7(g,h)+func8(i,(a)=>a+2)),g+2)"
	var done = get_functions("x += my_func(x, quest.win(y)) + sin(nein())")
	print(done)
#	var exp := Expression.new()
#	exp.parse("who_is(0, 1)")
#	print(exp.execute([], self))
	return

func call(f:StringName):
	print("CALLED ", f)

var calls = {
	ass=func(x): return "OK%sAY" % x
}

func fix_functions(t: String) -> String:
	var i := 0
	var out := ""
	var off := 0
	while i < len(t):
		var j := t.find("(", i)
		# find a bracket.
		if j != -1:
			var k := j-1
			var method_name := ""
			# walk backwards
			while k >= 0 and t[k] in ".abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789":
				method_name = t[k] + method_name
				k -= 1
			# if head isn't empty, it's a function not wrapping brackets.
			if method_name != "":
				out += UString.part(t, i, k+1)
				# don't wrap property methods, since those will be globally accessible from _get
				# don't wrap built in GlobalScope methods (sin, round, randf...)
				if "." in method_name or method_name in UObject.GLOBAL_SCOPE_METHODS:
					out += "%s(" % method_name
				else:
					out += "_C.%s.call(" % method_name
				out += UString.part(t, k+1+len(method_name), j)
				i = j + 1
				continue
		i += 1
	# add on the remainder.
	out += UString.part(t, i-2)
	return out
