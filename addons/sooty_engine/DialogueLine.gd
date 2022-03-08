extends Resource
class_name DialogueLine

@export var _dialogue_id: String
@export var _data := {}

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

# recursively go through options
# checking for ::, which imports options from another flow
func _get_options(input: Array, output: Array, depth: int):
	if depth > 4:
		push_error("Possible loop!?")
		return
		
	for i in len(input):
		var opdata := dialogue.get_line(input[i])
		if "flow" in opdata:
			if opdata.flow == "call":
				var fid: String = opdata.call
				var flines := Dialogues.get_flow_lines(fid)
				_get_options(flines, output, depth+1)
		else:
			output.append(opdata)

func get_options(only_passing: bool = false) -> Array[DialogueLine]:
	var out := []
	
	if "options" in _data:
		# recursively select options
		var lines: Array[String] = _data.options
		var first_pass: Array[Dictionary] = []
		_get_options(lines, first_pass, 0)
		
		# check which ones pass their condition
		for i in len(first_pass):
			var opdata := first_pass[i]
			
			if only_passing and "condition" in opdata and not StringAction.test(opdata.condition):
				continue
			
			out.append(DialogueLine.new(_dialogue_id, opdata))
	
	return out

func _to_string() -> String:
	return "DialogueLine(%s)" % _data
