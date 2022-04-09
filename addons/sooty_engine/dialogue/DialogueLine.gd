#extends Resource
#class_name DialogueLine
#
#@export var _dialogue_id: String
#@export var _data := {}
#@export var passed := true
#
#func _init(dialogue: String, data: Dictionary):
#	_dialogue_id = dialogue
#	_data = data
#
#var line: int:
#	get: return _data.line
#
#var dialogue: Dialogue:
#	get: return Dialogue.get_dialogue(_dialogue_id)
#
#var from: Variant:
#	get: return _data.get("key", "")
#
#var text: String:
#	get: return _data.get("val", "")
#

#
#func _to_string() -> String:
#	return "DialogueLine(%s)" % _data
