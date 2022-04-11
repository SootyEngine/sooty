@tool
extends EditorScript

func _run():
	Mods.load_mods()
	print(StringAction.do("$:time.weekday_index += 20"))
