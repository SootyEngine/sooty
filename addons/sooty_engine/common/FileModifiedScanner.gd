extends Timer
class_name FileModifiedScanner
# checks if files were modified, and emits a signal if so.

signal modified()

@export var files := []
@export var times := {}

func _ready() -> void:
	timeout.connect(_timeout)
	
func set_files(f: Array):
	files = f
	update_times()
	print("got files ", files, time_left)

func _timeout():
	if was_modified():
		stop()
		modified.emit()
		print("Modified: ", ", ".join(get_modified_files()))

func update_times():
	times.clear()
	for file in files:
		times[file] = UFile.get_modified_time(file)
	start()

func get_modified_files() -> Array:
	return files.filter(_was_file_modified)

func was_modified() -> bool:
	for file in files:
		if _was_file_modified(file):
			return true
	return false

func _was_file_modified(file: String) -> bool:
	return not file in times or UFile.get_modified_time(file) != times[file]
