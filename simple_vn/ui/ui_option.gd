extends Button

func set_option(o: DialogueLine):
	$text.set_bbcode(o.text)
