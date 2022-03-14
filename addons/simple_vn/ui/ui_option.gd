extends Button

@onready var label: RichTextLabel2 = $MarginContainer/text

var option: DialogueLine
var hovered := false:
	set(h):
		if h != hovered:
			hovered = h
			$back.visible = hovered
			_update_text()

func set_option(o: DialogueLine):
	option = o
	disabled = not option.passed
	_update_text()
	
func _update_text():
	var text = option.text
	
	if not option.passed:
		text = "[dim][lb]DEBUG[rb]%s[]" % text
	
	if hovered:
		label.set_bbcode("[sin;tomato]%s[]" % [text])
	else:
		label.set_bbcode(text)
