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
	get: return DialogueServer.get_dialogue(_dialogue_id)

var parent: DialogueLine:
	get: return DialogueLine.new(_dialogue_id, dialogue.get_line(_data.parent))

var option_index: int:
	get: return _data.get("option_index", -1)

var text: String:
	get: return _data.get("text", "")

var from: String:
	get: return _data.get("from", "")

func has_options() -> bool:
	return "options" in _data

func get_options(only_passing: bool = false) -> Array:
	var out := []
	
	if "options" in _data:
		for i in len(_data.options):
			var line = _data.options[i]
			var opdata := dialogue.get_line(line)
			
			if only_passing and "condition" in opdata and not StringAction.test(opdata.condition):
				continue
			
			var opline := DialogueLine.new(_dialogue_id, opdata)
			out.append(opline)
	
	return out

func _to_string() -> String:
	return "DialogueLine(%s)" % _data
