extends Resource
class_name DialogueLine

@export var _dialogue_id: String
@export var _data := {}
@export var passed := true

func _init(dialogue: String, data: Dictionary):
	_dialogue_id = dialogue
	_data = data

var line: int:
	get: return _data.line

var dialogue: Dialogue:
	get: return Dialogues.get_dialogue(_dialogue_id)

var text: String:
	get: return _data.get("text", "")

var from: Variant:
	get: return _data.get("from", null)

func has_options() -> bool:
	return "options" in _data

func _get_options(input: Array, output: Array, depth: int):
	if depth > 4:
		push_error("Possible loop!?")
		return
	
	for i in len(input):
		var opdata := dialogue.get_line(input[i])
		var passed := true
		if "cond" in opdata:
			passed = StringAction.test(opdata.cond)
		
		match opdata.get("flag", ""):
			"++":
				# recursively collect options from other flows
				if passed:
					var fid: String = opdata.text
					var flines := dialogue.get_flow_lines(fid)
					_get_options(flines, output, depth+1)
			_:
				var l := DialogueLine.new(_dialogue_id, opdata)
				l.passed = passed
				output.append(l)
#		if "flow" in opdata:
#			if opdata.flow == "call":
#				var fid: String = opdata.call
#				var flines := Dialogues.get_flow_lines(fid)
#				_get_options(flines, output, only_passing, depth+1)
#		else:
#			if only_passing and "cond" in opdata and not StringAction.test(opdata.cond):
#				continue
#
#			out.append(DialogueLine.new(_dialogue_id, opdata))

func get_options() -> Array[DialogueLine]:
	var out_lines: Array[DialogueLine] = []
	if "options" in _data:
		var all_lines: Array[String] = _data.options
		_get_options(all_lines, out_lines, 0)
	return out_lines

func _to_string() -> String:
	return "DialogueLine(%s)" % _data
