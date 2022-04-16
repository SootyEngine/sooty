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
#	var safety := 100
#	var script: Script = Dialogue.get_script()
#	while script and safety > 0:
#		print(script.resource_path)
#		script = script.get_base_script()
#		safety -= 1
	UDict.log(UScript.get_method_infos(Dialogue))
	
#	var out := {}
#	for file in UFile.get_files("res://addons/rich_text/text_effects", ".gd"):
#		var script = load(file).new()
#		print(script.get("bbcode"), script.get("info"))
	
#	var clr := Color.WHITE
#	var clrs := []
#	for i in clr.get_named_color_count():
#		clrs.append([i, clr.get_named_color(i), UColor.hue_shift(clr.get_named_color(i), 0.0)])
#	clrs.sort_custom(func(a, b): return a[1].h < b[1].h)
#	var list1 = clrs.map(func(x): return x[0])
#	clrs.sort_custom(func(a, b): return a[2].h < b[2].h)
#	var list2 = clrs.map(func(x): return x[0])
#	print(list1 == list2)
#	print(list1)
#	print(list2)
	
#	Global.meta.clear()
##	var script: Script = UClass.get_class_from_name("DataManager")
#	print("Data: ", Data.new()._get_class())
#	print("DataManager: ", DataManager.new()._get_class())
#	Mods.load_mods()
#	for item in State.my_manager:
#		print(item)
#	UDict.log(Global.meta)
	
#	var e := Expression.new()
#	e.parse("MyEnum.y")
#	print(e.execute())
#	for s in [
#		"my_func(x, 'yes okay', but)",
#		"(x, 'yes okay', but)",
#		"my_func (x, 'yes okay', but)",
#		"my_func(x, 'no') yes"]:
#		var mid = s.find("yes")
#		print(find_function(s, mid))
	
#	Mods.load_mods()
#	print(Global.get_tree().get_first_node_in_group("@:Music").get_groups())
#	var inv := Inventory.new()
#	var coin := Data._get_manager(Item).find("coin")
#	inv.gain(coin)
#	Mods.load_mods()
#	var inv := Inventory.new()
#	print(inv.get_manager())
#	print(UClass.get_class_name(inv))
	
#	print(StringAction.do("~$items.coin.get_class()"))
	
#	var inv := Inventory.new()
#	var info := UObject.get_method_info(inv, "gain")
#	print(info, UType.get_name_from_type(info.args[0].type))
#	var manager_classname = info.args[0].classname + "Manager"
#	if UClass.exists(manager_classname):
#		var items = State.get_first(manager_classname)
#		var ids = items.get_all_ids()
#		print(ids)
#	else:
#		print("No manager ", manager_classname)
	
#	var exp := Expression.new()
#	exp.parse("max(10, 20)")
#	print(exp.execute())
#
#	return
	
#	Mods.load_mods(false)
#	State.changed_from_to.connect(func(x, f, t): print("CHANGED %s FROM %s TO %s" % [x, f, t]))
#	var f := Flow.new(Dialogue._lines, Dialogue._flows)
#	prints(f.execute("East"), State.score)

#	for p in get_children("/"):
#		print("\t", p)
	
	
#	var tree := generate_tree()
#	print(get_children(tree, "the_beach"))
	pass
#	pri.nt("Okay")


