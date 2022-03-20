extends CanvasLayer

@onready var output: RichTextLabel2 = $c/c/output
@onready var input: LineEdit = $c/input

enum LineType { INPUT, LOG, ERROR, WARNING }

var lines := []

var show_log := true
var show_error := true
var show_warnings := true

var history := []
var history_index := 0:
	set(h):
		history_index = clampi(h, 0, len(history)-1)
		if len(history):
			_set_input(history[history_index])

func _ready() -> void:
	input.text_submitted.connect(_text_submitted)
	add_line(LineType.ERROR, "Not enough.")
	add_line(LineType.WARNING, "Not enough.")

func _text_submitted(t: String):
	history.append(t)
	history_index = len(history)
	add_line(LineType.INPUT, t)
	_set_input("")

func add_line(type: LineType, text: String):
	var s = get_stack()[-1]
	var msg: String
	if type == LineType.INPUT:
		msg = "\t[b]>[/b] %s" % [text]
	else:
		msg = "[b][%s:%s:%s][/b] %s" % [s.source.get_file(), s.function, s.line, text]
	lines.append([type, msg])
	redraw()
	
func redraw():
	output.clear()
	for line in lines:
		match line[0]:
			LineType.ERROR: output.push_color(Color.RED)
			LineType.WARNING: output.push_color(Color.YELLOW)
			LineType.WARNING: output.push_color(Color.AQUAMARINE)
		output.append_text(line[1])
		match line[0]:
			LineType.ERROR: output.pop()
			LineType.WARNING: output.pop()
			LineType.WARNING: output.pop()
		output.newline()

func _set_input(t: String):
	input.text = t
	input.caret_column = len(t)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action("ui_up"):
		history_index -= 1
	elif event.is_action("ui_down"):
		history_index += 1
