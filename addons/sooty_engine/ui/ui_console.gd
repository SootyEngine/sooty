extends Control

@onready var output: RichTextLabel = $c/c/output
@onready var input: LineEdit = $c/input

enum LineType { INPUT, LOG, ERROR, WARNING, RESULT }

var lines := []

var show_log := true
var show_error := true
var show_warnings := true

var history := [""]
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
	t = t.strip_edges()
	if not len(t):
		return
	
	history[-1] = t
	history.append("")
	history_index = len(history)
	add_line(LineType.INPUT, t)
	_set_input("")
	
	if t[0] in "~@$":
		var got = State.do(t)
		add_line(LineType.RESULT, str(got))
	else:
		var parts := UString.split_on_spaces(t)
		match parts[0]:
			"list": _list(State._get_all_of_class(parts[1]))

func _list(item):
	if item is Dictionary:
		for k in item:
			add_line(LineType.RESULT, "%s: %s" % [k, item[k]])

func add_line(type: LineType, text: String):
	var s = get_stack()[-1]
	var msg: String
	if type == LineType.INPUT:
		msg = "[b]>[/b] %s" % [text]
	else:
		var address := "[%s:%s %s]" % [s.source.get_file(), s.line, s.function]
		var spaces := " ".repeat((42-len(text)) + (42-len(address)))
		msg = "\t%s%s[b][color=#00000080]%s[/color][/b]" % [text, spaces, address]
	lines.append([type, msg])
	redraw()
	
func redraw():
	output.clear()
	for line in lines:
		match line[0]:
			LineType.ERROR: output.push_color(Color.RED)
			LineType.WARNING: output.push_color(Color.YELLOW)
#			LineType.WARNING: output.push_color(Color.AQUAMARINE)
			LineType.RESULT: output.push_color(Color.CORNFLOWER_BLUE)
		output.append_text(line[1])
		match line[0]:
			LineType.ERROR: output.pop()
			LineType.WARNING: output.pop()
			LineType.RESULT: output.pop()
		output.newline()

func _set_input(t: String):
	input.text = t
	input.caret_column = len(t)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action("ui_up"):
		history_index -= 1
	elif event.is_action("ui_down"):
		history_index += 1
