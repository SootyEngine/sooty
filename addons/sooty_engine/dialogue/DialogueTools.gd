@tool
extends  RefCounted
class_name DialogueTools

const FORMAT_ACTION := "[gray;i]*%s*[]"
const FORMAT_PREDICATE := "[dim]%s[]"
const FORMAT_QUOTE := "[q]%s[]"
const FORMAT_INNER_QUOTE := "[i]%s[]"
const QUOTE_DELAY := 0.25 # a delay between predicates and quotes.

const LAST_SPEAKER := "LAST_SPEAKER"

static func str_to_dialogue(s: String) -> Dictionary:
	var speaker_split := _find_speaker_split(s, 0)
	var from := ""
	var text := ""
	var action := []
	
	if speaker_split == -1:
		text = s
	
	else:
		var p := s.split(":", true, 1)
		from = s.substr(0, speaker_split).strip_edges().replace("\\:", ":")
		text = s.substr(speaker_split+1, len(s)-speaker_split).strip_edges()
		# get action
		if "(" in from:
			var a := UString.extract(from, "(", ")", true)
			from = a.outside
			for part in a.inside.split(";"):
				action.append("@%s.%s" % [from, part])
			action = action
		# signal that a speaker is desired but not given
		if from.strip_edges() == "":
			from = LAST_SPEAKER
		text = text.replace("\\:", ":")
	
	return {from=from, text=text, action=action}

static func _find_speaker_split(text: String, from: int) -> int:
	var in_bbcode := false
	for i in range(from, len(text)):
		match text[i]:
			"[": in_bbcode = true
			"]": in_bbcode = false
			":":
				if not in_bbcode and (i==0 or text[i-1] != "\\"):
					return i
	return -1

static func str_to_speaker(from: String) -> String:
	if from:
		# if wrapped, use as is.
		if UString.is_wrapped(from, '"'):
			from = UString.unwrap(from, '"')
		
		# if multiple names, join them together.
		elif " " in from:
			var names = Array(from.split(" "))
			for i in len(names):
				if State._has(names[i]):
					names[i] = UString.get_string(State._get(names[i]), "speaker_name")
			from = names.pop_back()
			if len(names):
				from = ", ".join(names) + ", and " + from
		
		# if a state, format it's text.
		elif State._has(from):
			from = UString.get_string(State._get(from), "speaker_name")
	
	return from

static func str_to_caption(from: String, text: String) -> String:
	if from:
		return _str_to_caption(text,
		"(", ")",
		"[i;dim]", "[]",
		"[dima]%s[]" % UString.CHAR_QUOTE_OPENED, "[dima]%s[]" % UString.CHAR_QUOTE_CLOSED)
	else:
		return _str_to_caption(UString.fix_quotes(text),
		UString.CHAR_QUOTE_OPENED, UString.CHAR_QUOTE_CLOSED,
		UString.CHAR_QUOTE_OPENED, UString.CHAR_QUOTE_CLOSED,
		'[dim]', '[]')

static func _str_to_caption(text: String,
	inner_opened := "(",
	inner_closed := ")",
	quote_opened := "{",
	quote_closed := "}",
	pred_opened := "<",
	pred_closed := ">"
	) -> String:
	var out := ""
	var leading := ""
	
	var in_pred := not text.begins_with(inner_opened)
	var start := true
	var started := false
	var in_tag := false
	
	for c in text:
		if c == "[":
			in_tag = true
			leading += c
		elif c == "]":
			in_tag = false
			leading += c
		elif in_tag:
			leading += c
		
		elif c == inner_opened:
			in_pred = false
			start = true
			if started:
				out += pred_closed
			leading += quote_opened
		
		elif c == inner_closed:
			in_pred = true
			start = true
			out += quote_closed
		
		elif c == " ":
			leading += " "
		
		else:
			if in_pred:
				if leading:
					out += leading
					leading = ""
				
				if start:
					start = false
					started = true
					out += pred_opened
			
			else:
				if leading:
					out += leading
					leading = ""
			
			out += c
	
	if in_pred and not start:
		out += pred_closed
	
	return out


