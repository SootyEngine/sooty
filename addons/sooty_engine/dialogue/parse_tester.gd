@tool
extends EditorScript

func _run():
	UDict.log(DataParser.new().parse("res://data.data"))
	return
