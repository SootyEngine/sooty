@tool
extends EditorScript

func _run():
	print(File.new().get_modified_time("res://dialogue"))
#	var test := TestClass.new()
#	StringAction.add_command(test.testy)
#	var got = StringAction.do_command("> testy")
#	print("GOT: ", got)
#	var path := ["res://states/characters.soda"]
#	var data = DataParser.parse(path[0]).data
##	UDict.log(data)
#	var o := PatchableData.new()
##	UDict.log(DataParser.patch_to_var(data, path))
#	DataParser.patch(o, data, path)
##	print(o.dict.new_line_property)
#	UDict.log(o.dict._extra)
#	UDict.log(UObject.get_state(o.dict._extra))
	
#	var a = Ass.new()
#	prints("name" in a, "x" in a, "y" in a)
#	prints(a, typeof(a), UType.get_name_from_type(typeof(a)))
#	DialogueLang.new("res://dialogue/dummy.soot").parse()
#	var d := Dialogue.new("dummy", ["res://dialogue/dummy.soot"], ["res://lang/dummy-fr.sola"])
#	d.generate_language_file("fr")
#	UDict.log(d.lines)
#	var c = "1234024"
#	print(str2var("123_4123_32"))
	
#	var dp = DataParser.new()
#	var d = dp.parse("res://data.soda")
#	print(dp.dict_to_str(d))
