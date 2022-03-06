extends Control

func setup(info: Dictionary):
	$HBoxContainer/VBoxContainer/Label.text = info.text
	var t := get_tree().create_timer(5.0)
	t.timeout.connect(queue_free)
