extends ConfirmationDialog

var data := {}

func _ready() -> void:
	cancelled.connect(_on_cancelled)
	confirmed.connect(_on_confirmed)

func setup(text:String, accept=null, cancel=null):
	setup_dict({text=text, ok=accept, x=cancel})

func setup_dict(d: Dictionary):
	data = d
	set_size(Vector2.ZERO)
	set_title(d.get("title", get_title()))
	set_text(d.get("text", get_text()))
#	set_position((get_viewport().size - size) * 0.5)
#	show()
	popup_centered_ratio(0.01)

func _on_cancelled():
	if "x" in data and data.x:
		data.x.call()

func _on_confirmed():
	if "ok" in data and data.ok:
		data.ok.call()
