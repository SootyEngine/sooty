@tool
extends Resource
class_name DialogueLang

var lang := "en"

#func parse(flows: Dictionary, lines: Dictionary):
#	# parse .soot
#	var parser := DialogueParser.new([soot_path], [])
#	parser.ignore_flags = true
#	var soot_data := parser.parse()
#	var soot_id := UFile.get_file_name(soot_path)
#
#	var raw_lines := UFile.load_text(soot_path).split("\n")
#	var sola_file := []
#	for id in ids:
#		var line_info: Dictionary = ids[id]
#		sola_file.append("<-> %s # %s @ %s" % [id, soot_path, line_info.line])
#		sola_file.append("\t# %s" % [_clean_raw_line(raw_lines[line_info.line])])
#		sola_file.append("\t")
#		sola_file.append("")
#
#	var out := "\n".join(sola_file)
#
#	print(sola_path)
#	UFile.save_text(sola_path, out)

func _clean_raw_line(text: String) -> String:
	if Soot.COMMENT_LANG in text:
		text = text.split(Soot.COMMENT_LANG, true, 1)[0]
	if Soot.COMMENT in text:
		text = text.split(Soot.COMMENT, true, 1)[0]
	return text.strip_edges()

#func set_line_uid(lines: PackedStringArray, line: int, uid: String):
#	if S_LANG_ID in lines[line]:
#		var p := lines[line].split(S_LANG_ID, true, 1)
#		lines[line] = p[0].strip_edges(false, true) + " #%s" % uid
#	else:
#		lines[line] = lines[line] + " #%s" % uid



