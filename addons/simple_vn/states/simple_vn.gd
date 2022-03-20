extends Node

var current_scene := ""
var last_speaker := ""
var flow_history := []
var flow_visited := {}
var caption_at := "bottom"
var caption_auto_clear := true
var time := DateTime.new({weekday="sat"})

func _init() -> void:
	DialogueStack.started.connect(_dialogue_started)
	DialogueStack.flow_started.connect(_flow_started)
	DialogueStack.flow_ended.connect(_flow_ended)
	DialogueStack.on_line.connect(_on_text)

#func _ready():
#	start.call_deferred()

func start():
	State.reset()
	DialogueStack.goto("MAIN.START", DialogueStack.STEP_GOTO)

func caption(kwargs: Dictionary):
	if "at" in kwargs:
		State._set("caption_at", kwargs.at)
	if "clear" in kwargs:
		State._set("caption_auto_clear", kwargs.clear)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		var waiting_for := []
		_caption_msg("advance", waiting_for)
		if len(waiting_for):
			pass
		else:
			_caption_msg("hide")
			DialogueStack.unhalt()

func _dialogue_started():
	flow_history.clear()

func _flow_started(flow: String):
	flow_history.append(flow)

func _flow_ended(flow: String):
	UDict.tick(flow_visited, flow) # tick number of times visited
	
	# goto the ending node
	if len(flow_history) and flow_history[-1] != "MAIN.END":
		DialogueStack.goto("MAIN.END", DialogueStack.STEP_GOTO)

const FORMAT_FROM := "[dim]｢[]%s[dim]｣[]"
var format_action:String = "[gray;i]*%s*[]"
var format_predicate:String = "[dim]%s[]"
var format_quote:String = "[q]%s[]"
var format_inner_quote:String = "[i]%s[]"
const QUOTE_DELAY := 0.5 # a delay between predicates and quotes.
const QUOTES := "[dim]“[]%s[dim]”[]" # nice quotes
const INNER_QUOTES := "[dim]‘[]%s[dim]’[]" # nice inner quotes

func _on_text(line: DialogueLine):
	var from = line.from
	if from == null:
		pass
	elif from == "":
		from = last_speaker
	elif last_speaker != "":
		last_speaker = from
	
	if from is String:
		if UString.is_wrapped(from, '"'):
			from = UString.unwrap(from, '"')
		
		elif " " in from:
			var names = Array(from.split(" "))
			for i in len(names):
				if State._has(names[i]):
					names[i] = Sooty.as_string(State._get(names[i]))
			from = names.pop_back()
			if len(names):
				from = ", ".join(names) + ", and " + from
			
		elif State._has(from):
			from = Sooty.as_string(State._get(from))
	
	DialogueStack.halt()
	_caption_msg("show_line", {from=FORMAT_FROM % from, text=_format(line.text, from != null), line=line})

func _format(text: String, has_from: bool) -> String:
	var out := ""
	var part_count := 0
	# when someone is speaking, use brakets to toggle 'predicate' mode.
	if has_from:
		var parts = UString.split_between(text, "(", ")")
		for p in parts:
			if not part_count == 0:
				out += "[w=%s]" % QUOTE_DELAY
			var whitespace = _get_whitespace_format(p)
			if UString.is_wrapped(p, '(', ')'):
				p = UString.unwrap(p, '(', ')').strip_edges()
				out += whitespace % format_predicate % p
			else:
				p = p.strip_edges()
				p = UString.replace_between(p, '"', '"', _replace_inner_quotes)
				out += whitespace % format_quote % QUOTES % p
			part_count += 1
	else:
		var parts = UString.split_between(text, "\"", "\"")
		for p in parts:
			if not part_count == 0:
				out += "[w=%s]" % QUOTE_DELAY
			var whitespace = _get_whitespace_format(p)
			if UString.is_wrapped(p, '"'):
				p = UString.unwrap(p, '"')
				p = UString.replace_between(p, "'", "'", _replace_inner_quotes)
				out += whitespace % format_quote % QUOTES % p
			else:
				p = p.strip_edges()
				out += whitespace % format_predicate % p
			part_count += 1
	return out

func _replace_inner_quotes(t: String) -> String:
	return format_inner_quote % INNER_QUOTES % t

# get the left and right whitespace, as a format string.
func _get_whitespace_format(s: String):
	var l := len(s) - len(s.strip_edges(true, false))
	var r := len(s) - len(s.strip_edges(false, true))
	return s.substr(0, l) + "%s" + s.substr(len(s) - r)

func _caption_msg(msg_type: String, msg: Variant = null):
	Global.call_group_flags(SceneTree.GROUP_CALL_REALTIME, "caption", "_caption", [State.caption_at, msg_type, msg])
