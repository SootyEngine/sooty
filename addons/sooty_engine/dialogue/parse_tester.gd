@tool
extends EditorScript

func _run():
	var dp = DataParser.new()
	var d = dp.parse("res://data.data")
	print(dp.dict_to_str(d))
