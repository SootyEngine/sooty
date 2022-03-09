@tool
extends Node

func _init() -> void:
	add_to_group("sa:scene")
	
func _get_tool_buttons():
	return ["test"]

func test():
	var d := DateTime.new({date="december 9 1989"})
	
	var d2 := DateTime.new({date="dec 25 1989"})
	
	prints(d.get_days_until(d2), d.get_relation(d2))
	
#	for i in 500:
#		prints(d.get_days_until(d2), d.get_relation(d2))
##		prints(d.date, d.year, d.daytime, d.weekday, d.weekend, d.days_until_weekend)
#		d.days += 45
		

func scene(id: String):
	for child in $scene.get_children():
		child.queue_free()
	
	for p in ["res://story_scenes/%s.tscn", "res://story_scenes/%s.scn"]:
		var path: String = p % id
		if UFile.file_exists(path):
			var sc: Node = load(path).instantiate()
			$scene.add_child(sc)
