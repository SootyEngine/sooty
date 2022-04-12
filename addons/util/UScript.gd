@tool
extends RefCounted
class_name UScript

func scan_scripts():
	for file in UFile.get_files("res://", "gd"):
		print(file)
