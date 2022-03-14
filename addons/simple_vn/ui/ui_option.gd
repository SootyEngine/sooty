extends Button

@onready var label: RichTextLabel2 = $MarginContainer/text

var option: DialogueLine
var hovered := false:
	set(h):
		if h != hovered:
			hovered = h
			if hovered:
				label.set_bbcode("[sin;tomato]%s[]" % [option.text])
				$back.visible = true
			else:
				label.set_bbcode(option.text)
				$back.visible = false

func set_option(o: DialogueLine):
	option = o
	label.set_bbcode(o.text)
