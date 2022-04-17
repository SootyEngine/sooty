@tool
extends EditorScript

func find_function(s: String, from: int):
	# look backwards till we find the start (
	var start := from
	var found_start := false
	while start > 0:
		if s[start] == "(":
			found_start = true
			break
		start -= 1
	if not found_start:
		return {}
	
	# look forwards till we find end end )
	var end := from
	var found_end := false
	while end < len(s):
		if s[end] == ")":
			found_end = true
		end += 1
	if not found_end:
		return {}
	
	# ignore if there is a space before the brackets
	if start == 0 or s[start-1] == " ":
		return {}
	
	# look backwards from start to find func name
	var f_start := start
	while f_start > 0 and s[f_start] != " ":
		f_start -= 1
	# extract function name
	var f_name := s.substr(f_start, start-f_start)
	var found_func := len(f_name) > 0
	if not found_func:
		return {}
	
	# divide the args
	var inner := s.substr(start+1, end-start-2)
	var args := UString.split_outside(inner, ",")
	
	# find the index of the current arg
	var a := start+1
	var arg_index := -1
	for i in len(args):
		a += len(args[i])+1
		if a >= from:
			arg_index = i
			break
	
	# strip argument edges
	args = args.map(func(x): return x.strip_edges())
	
	
	return {method=f_name, args=args, current_arg=arg_index}

enum MyEnum {x, y, z}

func _run():

	UDict.log(UReflect.get_method_infos(Dialogue))
	
	pass
#	pri.nt("Okay")


