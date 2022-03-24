extends Node

func _init() -> void:
	Mods.loaded.connect(_redraw)

func _redraw():
	var text := []
	var meta := {}
	
	text.append("[b]MUSIC[]")
	text.append("[meta stop_music]Stop[]")
	meta["stop_music"] = Music.stop()
	
	for id in Music._files:
		text.append("[meta music:%s]\t%s[]" % [id, id])
		meta["music:"+id] = Music.play.bind(id)
		
	text.append("[b]SFX[]")
	for id in SFX._files:
		text.append("[meta sfx:%s]\t%s[]" % [id, id])
		meta["sfx:"+id] = SFX.play.bind(id)
	
	$RichTextLabel.set_bbcode("\n".join(text))
	$RichTextLabel._meta = meta
