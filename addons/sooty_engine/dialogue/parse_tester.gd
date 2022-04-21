@tool
extends EditorScript


func _run():
	var dt := DateTime.create_from_current()
	prints(dt, dt.month)
	for i in 13:
		dt.advance({months=1, days=15})
		prints(dt, dt.month)
