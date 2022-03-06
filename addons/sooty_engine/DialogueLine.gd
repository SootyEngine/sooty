extends Resource
class_name DialogueLine

var _dialogue: Dialogue
var _stack: DialogueStack
var _parent: DialogueLine
var _index: int
var _data := {}

func _init(stack: DialogueStack, dialogue: Dialogue, data: Dictionary):
	_stack = stack
	_dialogue = dialogue
	_data = data

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
			var opdata := _dialogue.get_line(line)
			
			if only_passing and "condition" in opdata and not StringAction.test(opdata.condition):
				continue
			
			var opline := DialogueLine.new(_stack, _dialogue, opdata)
			opline._parent = self
			opline._index = i
			out.append(opline)
	
	return out

# Used for options.
func select() -> bool:
	if _parent and _stack and "lines" in _data:
		_stack.select_option(_parent._data, _index)
		return true
	push_error("Line is not an Option.")
	return false

func _to_string() -> String:
	return "DialogueLine(%s)" % _data
